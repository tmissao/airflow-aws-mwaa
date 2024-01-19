import pyspark
import argparse

from pandas import DataFrame as PdDataFrame
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

SPARK_LOCAL_CONFIGS: dict[str, str] = {
    'spark.jars.packages': 'org.postgresql:postgresql:42.7.1'
}

SPARK_GLOBAL_CONFIGS: dict[str, str] = {
}

def get_spark_session(is_local: bool = False) -> SparkSession:
    builder = SparkSession.builder.appName("Simple")
    configs = None
    
    if is_local:
        configs = SPARK_GLOBAL_CONFIGS | SPARK_LOCAL_CONFIGS
    else:
        configs = SPARK_GLOBAL_CONFIGS

    for k,v in configs.items():
        builder.config(k, v)
        
    return builder.getOrCreate()


def run(spark: SparkSession, database_url: str, database_user: str, database_password: str):
    table = "projects"

    properties = {
        "url": database_url,
        "user": database_user,
        "password": database_password,
        "driver": "org.postgresql.Driver"
    }

    df_table = (
            spark.read.format("jdbc")
            .options(**properties)
            .option("dbtable", table)
            .load()
    )

    df_query = (
            spark.read.format("jdbc")
            .options(**properties)
            .option("query", "Select * from projects p where p.name like 'Spokane%' ")
            .load()
    )

    print('df_table')
    df_table.show(10)

    print('==========================================================================')

    print('df_query')
    df_query.show(10)
    


def setup_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--local', help="Allow PySpark to Download Spark Dependencies", default=False, action="store_true"
    )
    parser.add_argument(
        '--url', help="Database URL", required=True
    )
    parser.add_argument(
        '--user', help="Database User", required=True
    )
    parser.add_argument(
        '--password', help="Database Password", required=True
    )
    return parser.parse_args()

  

if __name__ == "__main__":
    args = setup_args()
    spark: SparkSession = get_spark_session(is_local=args.local)
    run(spark, args.url, args.user, args.password)
    spark.stop()
