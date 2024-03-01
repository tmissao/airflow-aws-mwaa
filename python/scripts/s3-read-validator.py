import pyspark
import argparse

from pandas import DataFrame as PdDataFrame
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

SPARK_LOCAL_CONFIGS: dict[str, str] = {
    'spark.jars.packages': 'org.apache.hadoop:hadoop-aws:3.3.4',
    'fs.s3.impl': 'org.apache.hadoop.fs.s3a.S3AFileSystem',
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


def run(spark: SparkSession, s3_source: str):
    # spark
    print(f"Spark version = {spark.version}")
    # hadoop
    print(f"Hadoop version = {spark._jvm.org.apache.hadoop.util.VersionInfo.getVersion()}")
    print(f"S3_source {s3_source}")
    df = spark.read.json(s3_source)
    df.show(10)
    rows = df.count()
    unique_rows = df.dropDuplicates(['id']).count()
    print(f'Number of rows: {rows}')
    print(f'Number of unique rows: {unique_rows}')
    
    


def setup_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--local', help="Allow PySpark to Download Spark Dependencies", default=False, action="store_true"
    )
    parser.add_argument(
        '--data_source', help="The URI for you CSV restaurant data, like an S3 bucket location.", required=True
    )
    parser.add_argument(
        '--s3_endpoint', help="S3 Region Endpoint.", required=True
    )
    return parser.parse_args()

  

if __name__ == "__main__":
    args = setup_args()
    spark: SparkSession = get_spark_session(is_local=args.local)
    run(spark, args.data_source)
    spark.stop()
