#!/bin/bash

set -e
set -u
set -o pipefail
# set -x

echo "#########################################################################################"
echo "#                       Starting Installing Docker                                      #"
echo "#########################################################################################"
yum install docker -y
usermod -a -G docker ec2-user

wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
chmod -v +x /usr/local/bin/docker-compose

systemctl enable docker.service
systemctl start docker.service

echo "#########################################################################################"
echo "#                              Setup PosgresDB                                          #"
echo "#########################################################################################"

echo "${DOCKER_COMPOSE}" | base64 --decode > docker-compose.yml
mkdir sql
echo "${SQL_SCRIPT_GENERATE_DATA}" | base64 --decode > sql/generate-data.sql
docker-compose -p postgres up -d

echo "#########################################################################################"
echo "#                       Starting EMR Serverless Jobs                                    #"
echo "#########################################################################################"

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` 
PUBLIC_IP=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

echo "#########################################################################################"
echo "#                    Starting EMR Serverless Simple Job                                 #"
echo "#########################################################################################"
aws emr-serverless start-job-run --region ${AWS_REGION} --name simple --application-id ${EMR_SERVERLESS_APPLICATION}\
    --execution-role-arn ${EMR_SERVERLESS_EXECUTOR_ROLE} --job-driver '{
        "sparkSubmit": {
            "entryPoint": "s3://${BUCKET_NAME}/scripts/simple.py"
        }
    }'     --configuration-overrides '{
        "monitoringConfiguration": {
            "s3MonitoringConfiguration": {
                "logUri": "s3://${BUCKET_NAME}/logs/"
            }
        }
    }'

echo "#########################################################################################"
echo "#            Starting EMR Serverless JDBC Job - Maven Dependencies                      #"
echo "#########################################################################################"
aws emr-serverless start-job-run --region ${AWS_REGION} \
    --name jdbc-maven \
    --application-id ${EMR_SERVERLESS_APPLICATION} \
    --execution-role-arn ${EMR_SERVERLESS_EXECUTOR_ROLE} \
    --job-driver "{
        \"sparkSubmit\": {
            \"entryPoint\": \"s3://${BUCKET_NAME}/scripts/jdbc.py\",
            \"sparkSubmitParameters\": \"--packages org.postgresql:postgresql:42.7.1\",
            \"entryPointArguments\": [
              \"--url\",
              \"jdbc:postgresql://$PUBLIC_IP:5432/postgres\",
              \"--user\",
              \"${POSTGRES_USER}\",
              \"--password\",
              \"${POSTGRES_PASSWORD}\"
            ]
        }
    }" \
    --configuration-overrides '{
        "monitoringConfiguration": {
            "s3MonitoringConfiguration": {
                "logUri": "s3://${BUCKET_NAME}/logs/"
            }
        }
    }'

echo "#########################################################################################"
echo "#              Starting EMR Serverless JDBC Job - S3 Dependencies                       #"
echo "#########################################################################################"
aws emr-serverless start-job-run --region ${AWS_REGION} \
    --name jdbc-s3 \
    --application-id ${EMR_SERVERLESS_APPLICATION} \
    --execution-role-arn ${EMR_SERVERLESS_EXECUTOR_ROLE} \
    --job-driver "{
        \"sparkSubmit\": {
            \"entryPoint\": \"s3://${BUCKET_NAME}/scripts/jdbc.py\",
            \"sparkSubmitParameters\": \"--jars s3://${BUCKET_NAME}/jars/postgresql-42.7.1.jar\",
            \"entryPointArguments\": [
              \"--url\",
              \"jdbc:postgresql://$PUBLIC_IP:5432/postgres\",
              \"--user\",
              \"${POSTGRES_USER}\",
              \"--password\",
              \"${POSTGRES_PASSWORD}\"
            ]
        }
    }" \
    --configuration-overrides '{
        "monitoringConfiguration": {
            "s3MonitoringConfiguration": {
                "logUri": "s3://${BUCKET_NAME}/logs/"
            }
        }
    }'

echo "#########################################################################################"
echo "#                 Starting EMR Serverless Custom Image Job                              #"
echo "#########################################################################################"

aws emr-serverless start-job-run --region ${AWS_REGION} \
    --name jdbc-s3-custom-docker-image \
    --application-id ${EMR_SERVERLESS_CUSTOM_IMAGE_APPLICATION} \
    --execution-role-arn ${EMR_SERVERLESS_EXECUTOR_ROLE} \
    --job-driver "{
        \"sparkSubmit\": {
            \"entryPoint\": \"s3://${BUCKET_NAME}/scripts/jdbc.py\",
            \"entryPointArguments\": [
              \"--url\",
              \"jdbc:postgresql://$PUBLIC_IP:5432/postgres\",
              \"--user\",
              \"${POSTGRES_USER}\",
              \"--password\",
              \"${POSTGRES_PASSWORD}\"
            ]
        }
    }" \
    --configuration-overrides '{
        "monitoringConfiguration": {
            "s3MonitoringConfiguration": {
                "logUri": "s3://${BUCKET_NAME}/logs/"
            }
        }
    }'


echo "#########################################################################################"
echo "#                        Starting EMR Serverless S3 Job                                 #"
echo "#########################################################################################"
aws emr-serverless start-job-run --region ${AWS_REGION} --name s3 --application-id ${EMR_SERVERLESS_APPLICATION}\
    --execution-role-arn ${EMR_SERVERLESS_EXECUTOR_ROLE} --job-driver '{
        "sparkSubmit": {
            "entryPoint": "s3://${BUCKET_NAME}/scripts/s3.py",
            "entryPointArguments": [
              "--data_source",
              "s3://${BUCKET_NAME}/data/cities.csv",
              "--output_uri",
              "s3://${BUCKET_NAME}/reports/cities",
              "--s3_endpoint",
              "s3-${AWS_REGION}.amazonaws.com"
            ]
        }
    }' --configuration-overrides '{
        "monitoringConfiguration": {
            "s3MonitoringConfiguration": {
                "logUri": "s3://${BUCKET_NAME}/logs/"
            }
        }
    }'