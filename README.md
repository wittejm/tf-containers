This is a setup to run old versions of terraform locally, in a container, because some workspaces depend on old versions of terraform that don't have an ARM binary.

This `Dockerfile` has a hard-coded TF version. For now, to support a different tf version, update the Dockerfile and rebuild it with:

`docker build -t image-name .` in this directory. This names the image `image-name` (I call mine `my-tf`). As an optional new strategy, start building versioned image names. Personally, as this tool matures I want to maintain just one named image so I'll rewrite it each time I need a different terraform version.

Run a container from the docker image in the  app's terraform directory. If the workspace refers to adjacent directories, run the container in a shared parent directory, and in the container `cd` to the workspace inside the container. In the example below, change the aws account-name and role-name

`docker run -it -e GIT_TOKEN=$GIT_TOKEN -e NEW_RELIC_API_KEY=$NEW_RELIC_API_KEY --env-file <(creds msls-dev msls-developer-admin) --platform linux/amd64 -v $(pwd):/terraform my-tf`

the `$GIT_TOKEN` is a PAT, which I have set locally. the `env-file` argument takes a call to `creds`, which I have aliased in .zshrc:
`alias creds=/Users/jordan/Dropbox/tf-containers/get_aws_creds.sh`

The script `get_aws_creds.sh` accepts an aws profile name that needs to have been configured in `~/.aws/config`, and a role name.

To configure a new account in that file, obtain the account-id and role name by navigating to cloudtamer https://cloudtamer.cms.gov/ while on zscaler.

The setup needs git access to all of the CMS repos that contain tf module dependencies. This has been set up using the `git-credentials-helper.sh` and calling `git config` in the Dockerfile. 

Issues I have encountered:

- `terraform init` fails to download git repos, saying username/password is not allowed and ssh or a PAT are required. This has happened because $GIT_TOKEN was not being passed in. Also a few days ago this error occurred and my eventual fix was to re-generate and pass in a new PAT, even though my current PAT hadn't expired.

