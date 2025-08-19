#!/bin/sh

log() {
  echo "[LOG] $@" >&2
}

if [ "$#" -eq 0 ]; then
  log "No arguments provided."
  log "Checking if kion.yml file exists in current directory..."
  if ! [ -f 'kion.yml' ]; then
    log "No kion.yml file exists in current directory"
    exit 1
  fi

  log 'A kion.yml file found in current directory'
  use_kion_file='true'
else
  log "Arguments provided. Number of arguments: $#"
  if [ -z "$2" ]; then
    log "Usage: $0 <aws-profile> <role-name>"
    exit 1
  fi

  aws_profile=$1
  role_name=$2
  use_kion_file='false'
fi

# Get AWS caller identity
if [ "$use_kion_file" != 'true' ]; then
  log 'Getting AWS caller identity'
  aws_output=$(aws --profile $aws_profile sts get-caller-identity)
fi


log 'Exporting Kion credentials'
if [ "$use_kion_file" = 'true' ]; then
  $(kion credentials -f export)
else
  # Extract the account number using jq
  account_id=$(echo $aws_output | jq -r '.Account')

  # if we're able to extract the correct role from the arn, that's great.
  #role_arn=$(echo $aws_output | jq -r '.Arn')

  $(kion credentials --account-id $account_id --cloud-access-role $role_name -f export)
fi

echo AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
echo AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
echo AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN

log 'Starting Terraform container'