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

JDBC_ENTRYPOINT_ARGS = [
    "--url",
    f'jdbc:postgresql://{Variable.get("postgres-hostname")}:5432/postgres',
    "--user",
    Variable.get("postgres-user"),
    "--password",
    Variable.get("postgres-password")
]

EMR_EXECUTION_ROLE=Variable.get("emr-executor-role-arn")

with DAG(dag_id="emr-serverless-jdbc", default_args=DAG_DEFAULT_ARGS, schedule_interval="@daily") as dag:

    create_basic_app = EmrServerlessCreateApplicationOperator(
        task_id="create-basic-app",
        release_label="emr-7.0.0",
        job_type="Spark",
        config={ "name": "airflow-basic-app", **EMR_BASE_CONFIGURATION }
    )

    create_custom_app = EmrServerlessCreateApplicationOperator(
        task_id="create-custom-app",
        release_label="emr-7.0.0",
        job_type="Spark",
        config={ 
            "name": "airflow-custom-app",
            "imageConfiguration": {
               "imageUri": Variable.get("emr-custom-image-tag")
            }, 
            **EMR_BASE_CONFIGURATION 
        }
    )

    basic_app_jdbc_maven = EmrServerlessStartJobOperator(
        task_id="basic-app-jdbc-maven",
        name="jdbc-maven",
        job_driver={
            "sparkSubmit": {
                "entryPoint": Variable.get("emr-s3-scripts-jdbc"),
                "entryPointArguments": JDBC_ENTRYPOINT_ARGS,
                "sparkSubmitParameters": "--packages org.postgresql:postgresql:42.7.1"
            }
        },
        application_id=create_basic_app.output,
        execution_role_arn=EMR_EXECUTION_ROLE,
        configuration_overrides={}
    )

    basic_app_jdbc_s3 = EmrServerlessStartJobOperator(
        task_id="basic-app-jdbc-s3",
        name="jdbc-maven",
        job_driver={
            "sparkSubmit": {
                "entryPoint": Variable.get("emr-s3-scripts-jdbc"),
                "entryPointArguments": JDBC_ENTRYPOINT_ARGS,
                "sparkSubmitParameters": f'--jars {Variable.get("emr-s3-jars-postgres")}'
            }
        },
        application_id=create_basic_app.output,
        execution_role_arn=EMR_EXECUTION_ROLE,
        configuration_overrides={}
    )

    custom_app_jdbc = EmrServerlessStartJobOperator(
        task_id="custom-app-jdbc-s3",
        name="jdbc-maven",
        job_driver={
            "sparkSubmit": {
                "entryPoint": Variable.get("emr-s3-scripts-jdbc"),
                "entryPointArguments": JDBC_ENTRYPOINT_ARGS,
            }
        },
        application_id=create_custom_app.output,
        execution_role_arn=EMR_EXECUTION_ROLE,
        configuration_overrides={}
    )

    stop_basic_app = EmrServerlessStopApplicationOperator(
        task_id = "stop-basic-app",
        application_id = create_basic_app.output
    )

    stop_custom_app = EmrServerlessStopApplicationOperator(
        task_id = "stop-custom-app",
        application_id = create_custom_app.output
    )

    notify_end = BashOperator(
      task_id="notify-end",
      bash_command="echo 'All Tasks End'"
    )

    create_basic_app >> [basic_app_jdbc_maven, basic_app_jdbc_s3] >> stop_basic_app
    create_custom_app >> custom_app_jdbc >> stop_custom_app
    [stop_basic_app, stop_custom_app] >> notify_end