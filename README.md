This is a setup useful on ARM hardware to run old versions of terraform locally, in a container, because some workspaces depend on old versions of terraform that don't have an ARM binary.

First, set the username in `git-credentials-helper.sh` to your EUA id, and build the container with `docker build -t image-name .` in this repo directory. This names the image `image-name` (I call mine `my-tf`).

This `Dockerfile` has a hard-coded terraform version. For now, to support a different version, update the version in the Dockerfile and rebuild it. As an optional new strategy, we could start building versioned image names. Personally, as this tool matures I want to maintain just one named image so I'll update the file each time I need a different terraform version.

The `docker run` call below is long, so shorten/standardize some of it by writing an alias for the script that gets called:

 `alias creds=/path/to/this/repo/get_aws_creds.sh` 
 
and putting it in your `.zshrc` file, etc.

Run this container from the docker image in the terraform directory of the app you want to run `terraform` on. If the files in the workspace refer to adjacent directories, you'll need to run the container in a shared parent directory, and in the container `cd` to the workspace where you want to run `terraform`. In the example below, change the `aws-profile-name` and `role-name` to the account for which you want to run `terraform`

The Docker run command is:

```
docker run -it -e GIT_TOKEN=$GIT_TOKEN -e NEW_RELIC_API_KEY=$NEW_RELIC_API_KEY --env-file <(creds aws-profile-name role-name) --platform linux/amd64 -v $(pwd):/terraform my-tf
```

the `$GIT_TOKEN` is a PAT (personal access token), which I have set locally. the `env-file` argument takes a call to `creds`, which requires the arguments `aws-profile-name` and `role-name`.

The `aws-profile-name` needs to be one that you have added to `~/.aws/config`. A profile in `~/.aws/config` needs to look like, for example:

```
[profile hsls-test]
credential_process = /path/to/kion credential-process --account-id ******** --cloud-access-role hsls-developer-admin
region = us-east-1
```

To configure a new account in that file, obtain the account-id and role name by navigating to cloudtamer https://cloudtamer.cms.gov/ while on zscaler.

The setup needs git access to all of the CMS repos that contain tf module dependencies. This has been set up using the `git-credentials-helper.sh` in this project, passing it into the built docker image, and calling `git config` in the Dockerfile. 

Issues I have encountered:

- `terraform init` fails to download git repos, saying username/password is not allowed and ssh or a PAT are required. This has happened because $GIT_TOKEN was not being passed in. Also this error occurred after the setup was working and my eventual fix was to re-generate and pass in a new PAT, even though my current PAT hadn't expired.
