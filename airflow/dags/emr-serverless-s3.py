import airflow.utils.dates
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.amazon.aws.operators.emr import (
    EmrServerlessCreateApplicationOperator,
    EmrServerlessStartJobOperator,
    EmrServerlessStopApplicationOperator
)
from airflow.models import Variable


DAG_DEFAULT_ARGS = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 0,
    "start_date": airflow.utils.dates.days_ago(1)
}

EMR_BASE_CONFIGURATION = {
    "tags": {"airflow": "true"},
    "autoStartConfiguration": {
        "enabled": True
    },
    "networkConfiguration": {
        "subnetIds": Variable.get("private-subnets-ids").split(","),
        "securityGroupIds": Variable.get("emr-workspace-sg-id").split(",")
    },
    "monitoringConfiguration": {
        "s3MonitoringConfiguration": {
            "logUri": Variable.get("emr-s3-log-directory")
        }
    }
}

ENTRYPOINT_ARGS = [
    "--data_source",
    f's3://{Variable.get("emr-s3-bucket-name")}/data/cities.csv',
    "--output_uri",
    f's3://{Variable.get("emr-s3-bucket-name")}/reports/cities',
    "--s3_endpoint",
    f's3.{Variable.get("aws-region")}.amazonaws.com'
]

EMR_EXECUTION_ROLE=Variable.get("emr-executor-role-arn")

with DAG(dag_id="emr-serverless-s3", default_args=DAG_DEFAULT_ARGS, schedule_interval="@daily") as dag:

    create_app = EmrServerlessCreateApplicationOperator(
        task_id="emr-serverless-s3",
        release_label="emr-7.0.0",
        job_type="Spark",
        config={ "name": "airflow-basic-app", **EMR_BASE_CONFIGURATION }
    )

    start_emr = EmrServerlessStartJobOperator(
        task_id="basic-app-s3",
        name="emr-s3-job",
        job_driver={
            "sparkSubmit": {
                "entryPoint": Variable.get("emr-s3-scripts-s3"),
                "entryPointArguments": ENTRYPOINT_ARGS,
            }
        },
        application_id=create_app.output,
        execution_role_arn=EMR_EXECUTION_ROLE,
        configuration_overrides={}
    )


    stop_emr = EmrServerlessStopApplicationOperator(
        task_id = "stop-basic-app",
        application_id = create_app.output
    )

    notify_end = BashOperator(
      task_id="notify-end",
      bash_command="echo 'All Tasks End'"
    )

    create_app >> start_emr >> stop_emr >> notify_end