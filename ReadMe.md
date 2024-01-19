
# EMR Serverless POC

## Simple Script
---
aws emr-serverless start-job-run --region us-west-2 \
    --name simple \
    --application-id 00fgcgig5fto4o0l \
    --execution-role-arn arn:aws:iam::801578398305:role/EmrServerlessExecutor \
    --job-driver '{
        "sparkSubmit": {
            "entryPoint": "s3://demo-emr-37908/scripts/simple.py"
        }
    }' \
    --configuration-overrides '{
        "monitoringConfiguration": {
            "s3MonitoringConfiguration": {
                "logUri": "s3://demo-emr-37908/logs/"
            }
        }
    }'

## Read Postgres with dependencies on Maven
---
aws emr-serverless start-job-run --region us-west-2 \
    --name jdbc \
    --application-id 00fgcgig5fto4o0l \
    --execution-role-arn arn:aws:iam::801578398305:role/EmrServerlessExecutor \
    --job-driver '{
        "sparkSubmit": {
            "entryPoint": "s3://demo-emr-37908/scripts/jdbc.py",
            "sparkSubmitParameters": "--packages org.postgresql:postgresql:42.7.1",
            "entryPointArguments": [
              "--url",
              "jdbc:postgresql://global-sonarqube-psql.postgres.database.azure.com:5432/postgres",
              "--user",
              "adminuser",
              "--password",
              "XXXXXXXXXXXXXXXXX"
            ]
        }
    }' \
    --configuration-overrides '{
        "monitoringConfiguration": {
            "s3MonitoringConfiguration": {
                "logUri": "s3://demo-emr-37908/logs/"
            }
        }
    }'

## Read Postgres with dependencies on S3
---
aws emr-serverless start-job-run --region us-west-2 \
    --name jdbc-s3-jar \
    --application-id 00fgcgig5fto4o0l \
    --execution-role-arn arn:aws:iam::801578398305:role/EmrServerlessExecutor \
    --job-driver '{
        "sparkSubmit": {
            "entryPoint": "s3://demo-emr-37908/scripts/jdbc.py",
            "sparkSubmitParameters": "--jars s3://demo-emr-37908/jars/postgresql-42.7.1.jar",
            "entryPointArguments": [
              "--url",
              "jdbc:postgresql://global-sonarqube-psql.postgres.database.azure.com:5432/postgres",
              "--user",
              "adminuser",
              "--password",
              "XXXXXXXXXXXXXXXXX"
            ]
        }
    }' \
    --configuration-overrides '{
        "monitoringConfiguration": {
            "s3MonitoringConfiguration": {
                "logUri": "s3://demo-emr-37908/logs/"
            }
        }
    }'

## Read/Write from S3
---
aws emr-serverless start-job-run --region us-west-2 \
    --name s3 \
    --application-id 00fgcgig5fto4o0l \
    --execution-role-arn arn:aws:iam::801578398305:role/EmrServerlessExecutor \
    --job-driver '{
        "sparkSubmit": {
            "entryPoint": "s3://demo-emr-37908/scripts/s3.py",
            "entryPointArguments": [
              "--data_source",
              "s3://acqio-dev-uswe2-applicationlogs-s3/logstash/2024/01/06/07/*",
              "--output_uri",
              "s3://demo-emr-37908/reports/emr-serverless",
              "--s3_endpoint",
              "s3-us-west-2.amazonaws.com"
            ]
        }
    }' \
    --configuration-overrides '{
        "monitoringConfiguration": {
            "s3MonitoringConfiguration": {
                "logUri": "s3://demo-emr-37908/logs/"
            }
        }
    }'


## Custom Docker Image with dependencies into it
---

aws emr-serverless start-job-run --region us-west-2 \
    --name jdbc-custom-image \
    --application-id 00fgdeqj886cn70l \
    --execution-role-arn arn:aws:iam::801578398305:role/EmrServerlessExecutor \
    --job-driver '{
        "sparkSubmit": {
            "entryPoint": "s3://demo-emr-37908/scripts/jdbc.py",
            "entryPointArguments": [
              "--url",
              "jdbc:postgresql://global-sonarqube-psql.postgres.database.azure.com:5432/postgres",
              "--user",
              "adminuser",
              "--password",
              "XXXXXXXXXXXXXXXXX"
            ]
        }
    }' \
    --configuration-overrides '{
        "monitoringConfiguration": {
            "s3MonitoringConfiguration": {
                "logUri": "s3://demo-emr-37908/logs/"
            }
        }
    }'

> Log is 'SPARK_DRIVE'

## Insightful links
---
https://aws.github.io/aws-emr-containers-best-practices/submit-applications/docs/spark/pyspark/#list-of-packages

https://github.com/aws-samples/emr-serverless-samples