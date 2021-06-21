#!/usr/bin/env bash -e

stack_name=proton-prerequisites
region=us-west-2

set -x
aws cloudformation update-stack \
    --stack-name ${stack_name} \
    --template-body file://./proton/prerequisites.yml \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${region}

{ set +x; } 2>/dev/null
echo "Track progress at https://console.aws.amazon.com/cloudformation"
set -x
aws cloudformation wait stack-update-complete \
    --stack-name ${stack_name} \
    --region ${region}
