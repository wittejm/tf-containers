

I tried building an old version from source and adding it to the `tfenv` list like so:

- Clone the official terraform repo from: https://github.com/hashicorp/terraform
- check out the desired version by version tag.
- build with `go build .`
- move the built version to tfenv's versions folder, which for me is here: `/opt/homebrew/Cellar/tfenv/3.0.0/versions`
- Verify that tfenv sees the version in that list using `tfenv list`
- Set the active version using `tfenv use`.

This didn't solve my problem because some plugins in that older workspace specifically didn't work on ARM.