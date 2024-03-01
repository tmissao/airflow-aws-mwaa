import airflow.utils.dates
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator

default_args = {
        "owner": "airflow", 
        "start_date": airflow.utils.dates.days_ago(1)
    }

with DAG(dag_id="sleep_dag", default_args=default_args, schedule_interval="@daily") as dag:

    t1 = EmptyOperator(task_id="t1")

    t2 = BashOperator(
            task_id="t2",
            bash_command="sleep 30"
        )
    
    t1 >> t2