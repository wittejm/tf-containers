This is a setup useful on ARM hardware to run old versions of terraform locally, in a container, because some workspaces depend on old versions of terraform that don't have an ARM binary.

First, set the username in `git-credentials-helper.sh` to your personal id, and build the container with `docker build -t image-name .` in this repo directory. This names the image `image-name` (I call mine `my-tf`).

This `Dockerfile` has a hard-coded terraform version. For now, to support a different version, update the version in the Dockerfile and rebuild it. As an optional new strategy, we could start building versioned image names. Personally, as this tool matures I want to maintain just one named image so I'll update the file each time I need a different terraform version.

The `docker run` call below is long, so shorten/standardize some of it by writing an alias for the script that gets called:

 `alias creds=/path/to/this/repo/get_aws_creds.sh` 
 
and putting it in your `.zshrc` file, etc.

## Run the Docker Container
There are two ways to run the Docker container:
1. Providing the AWS profile name and AWS role name to the `creds` alias
2. Allowing the `creds` alias to read the kion.yml file in the current directory

### Providing the AWS Profile and Role Names
Run this container from the docker image in the terraform directory of the app you want to run `terraform` on. If the files in the workspace refer to adjacent directories, you'll need to run the container in a shared parent directory, and in the container `cd` to the workspace where you want to run `terraform`. In the example below, change the `aws-profile-name` and `role-name` to the account for which you want to run `terraform`

The Docker run command is:

```
docker run -it -e GIT_TOKEN=$GIT_TOKEN -e NEW_RELIC_API_KEY=$NEW_RELIC_API_KEY --env-file <(creds aws-profile-name role-name) --platform linux/amd64 -v $(pwd):/terraform my-tf
```

the `$GIT_TOKEN` is a PAT (personal access token), which I have set locally. the `env-file` argument takes a call to `creds`, which requires the arguments `aws-profile-name` and `role-name`.

The `aws-profile-name` needs to be one that you have added to `~/.aws/config`. A profile in `~/.aws/config` needs to look like, for example:

```
[profile profile-name]
credential_process = /path/to/kion credential-process --account-id ******** --cloud-access-role role-name
region = us-east-1
```

To configure a new account in that file, obtain the account-id and role name by navigating to cloudtamer.

### Reading the Kion File
The `creds` alias is capable of reading the account and role information from AWS using the kion.yml file in the current directory if no arguments are passed to the alias.

The Docker run command is:
```
GIT_REPO="$(git rev-parse --show-toplevel)" && \
docker run \
-it \
--rm \
-e GIT_TOKEN=$GIT_TOKEN \
-e NEW_RELIC_API_KEY=$NEW_RELIC_API_KEY \
-e AWS_REGION='us-east-1' \
--env-file <(creds) \
-v "$GIT_REPO":/app \
-w "/app$(pwd | sed "s|$GIT_REPO||")" \
--platform linux/amd64 \
my-tf
```

The Git repository is mounted to the container as the `/app` volume (using the GIT_REPO variable) allowing the Terraform module in the current directory to reference other Terraform modules outside the current directory (within the same Git repository). This is necessary because the `docker run` command <b>MUST</b> be executed in the same directory as the kion.yml file. The container's working directory is set to the current directory relative to the Git repository (and relative to the `/app` volume).

Optionally, the GIT_TOKEN and NEW_RELIC_API_KEY container environment variables can be read from files:
```
-e GIT_TOKEN="$(cat <git_token_file>)" \
-e NEW_RELIC_API_KEY="$(cat <new_relic_api_key_file>)" \
```

The setup needs git access to all of the private repos that contain tf module dependencies. This has been set up using the `git-credentials-helper.sh` in this project, passing it into the built docker image, and calling `git config` in the Dockerfile.

Issues I have encountered:

- `terraform init` fails to download git repos, saying username/password is not allowed and ssh or a PAT are required. This has happened because $GIT_TOKEN was not being passed in. Also this error occurred after the setup was working and my eventual fix was to re-generate and pass in a new PAT, even though my current PAT hadn't expired.
