import airflow.utils.dates
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.amazon.aws.operators.s3 import S3CreateObjectOperator, S3ListOperator

default_args = {
        "owner": "airflow", 
        "start_date": airflow.utils.dates.days_ago(1)
    }

with DAG(dag_id="test-aws-s3", default_args=default_args, schedule_interval="@daily") as dag:

    t1 = BashOperator(
            task_id="sleep",
            bash_command="sleep 5"
        )

    t2 = S3CreateObjectOperator(
            task_id="t2",
            s3_key="airflow/hello-world.txt",
            s3_bucket='{{var.value.get("emr-s3-bucket-name")}}',
            data="Data Generated from Airflow, Hello World",
            replace=True
    )
    
    t3 = S3ListOperator(
        task_id="list_3s_files",
        bucket='{{var.value.get("emr-s3-bucket-name")}}',
        prefix="scripts/",
        delimiter="/",
    )
    
    t1 >> [t2, t3]