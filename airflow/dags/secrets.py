import airflow.utils.dates
from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator


default_args = {
    "owner": "airflow", 
    "start_date": airflow.utils.dates.days_ago(1)
}

PRIVATE_SUBNETS =  Variable.get("private-subnets-ids")

def show_secret(**kwargs):
    secret_from_code = Variable.get("private-subnets-ids")
    secret_from_template = kwargs["templates_dict"]["secret-template"]
    print(f'secret_from_code= {secret_from_code}')
    print(f'secret_from_template= {secret_from_template}')
    print(f'secret_from_global= {PRIVATE_SUBNETS}')

with DAG(dag_id="secrets_dag", default_args=default_args, schedule_interval="@daily") as dag:
    t1 = PythonOperator(
            task_id="t1",
            python_callable=show_secret,
            templates_dict={
                "secret-template": '{{var.value.get("private-subnets-ids")}}',
            }
        )