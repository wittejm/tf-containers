#!/bin/sh

if [ -z "$2" ]; then
  echo "Usage: $0 <aws-profile> <role-name>"
  exit 1
fi

aws_profile=$1
role_name=$2

aws_output=$(aws --profile $aws_profile sts get-caller-identity)

# Extract the account number using jq
account_id=$(echo $aws_output | jq -r '.Account')

# if we're able to extract the correct role from the arn, that's great.
#role_arn=$(echo $aws_output | jq -r '.Arn')

$(kion credentials --account-id $account_id --cloud-access-role $role_name -f export)

echo AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
echo AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
echo AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
