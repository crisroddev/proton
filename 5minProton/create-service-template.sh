#/usr/bin/env -e

set -x
. proton/variables

# Create the service template if it doesn't already exist
aws proton-preview get-service-template \
    --template-name "${service_template_name}" \
    --region ${region} 1>/dev/null 2>&1 ||
aws proton-preview create-service-template \
  --region us-west-2 \
  --template-name "${service_template_name}" \
  --display-name "LoadbalancedFargateService" \
  --description "Fargate Service with an Application Load Balancer"

# Create major version 1 of the template if it doesn't already exist
if [ 0 -eq $(aws proton-preview list-service-template-major-versions \
                --template-name ${service_template_name} \
                --region ${region} | jq -r '.templates | length') ]; then

    environment_arn=$(aws proton-preview get-environment-template \
        --template-name ${environment_template_name} \
        --region ${region} | jq -r '.environmentTemplate.arn')

    aws proton-preview create-service-template-major-version \
      --region ${region} \
      --template-name "${service_template_name}" \
      --description "Version 1" \
      --compatible-environment-template-major-version-arns $environment_arn:1
fi

# Prepare the service template archive to be used for version 1.0
cd proton
if [ ! -f $service_template_arch ]; then
    tar -zcvf $service_template_arch service/
fi
cd - >/dev/null

s3_bucket=$(get_s3_bucket)

# Upload the service template archive if it doesn't already exist
if ! aws s3 ls --region ${region} s3://${s3_bucket}/${service_template_arch} >/dev/null; then
    aws s3 cp proton/${service_template_arch} s3://${s3_bucket}/${service_template_arch} \
        --region ${region}
fi

# Create and publish minor version 1.0 if it doesn't already exist
if [ 0 -eq $(aws proton-preview list-service-template-minor-versions \
                --region ${region} \
                --template-name ${service_template_name} | jq -r '.templates | length') ]; then
    aws proton-preview create-service-template-minor-version \
      --region ${region} \
      --template-name "${service_template_name}" \
      --description "Version 1.0" \
      --major-version-id "1" \
      --source-s3-bucket ${s3_bucket} \
      --source-s3-key ${service_template_arch}

    aws proton-preview wait service-template-registration-complete \
      --region ${region} \
      --template-name "${service_template_name}" \
      --major-version-id "1" \
      --minor-version-id "0"

    aws proton-preview update-service-template-minor-version \
      --region ${region} \
      --template-name "${service_template_name}" \
      --major-version-id "1" \
      --minor-version-id "0" \
      --status "PUBLISHED"
fi
