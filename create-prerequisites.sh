#!/usr/bin/env bash -e

. proton/variables

if ! aws proton-preview help 1>/dev/null 2>&1; then
    # Install the aws CLI models for proton which is still in preview
    aws s3 cp s3://aws-proton-preview-public-files/model/proton-2020-07-20.normal.json .
    aws s3 cp s3://aws-proton-preview-public-files/model/waiters2.json .
    aws configure add-model --service-model file://proton-2020-07-20.normal.json --service-name proton-preview
    mv waiters2.json ~/.aws/models/proton-preview/2020-07-20/waiters-2.json
    rm proton-2020-07-20.normal.json
fi

aws proton-preview help >/dev/null && echo "proton-preview is available in the CLI" \
    || (echo "proton models were not installed correctly" && exit 1)

set -x
aws cloudformation create-stack \
    --stack-name ${stack_name} \
    --template-body file://./proton/prerequisites.yml \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${region}

{ set +x; } 2>/dev/null
echo "Track progress at https://${region}.console.aws.amazon.com/cloudformation"
set -x
aws cloudformation wait stack-create-complete \
    --stack-name ${stack_name} \
    --region ${region}
{ set +x; } 2>/dev/null

echo "Please complete any pending CodeStar connections in https://${region}.console.aws.amazon.com/codesuite/settings/connections"

