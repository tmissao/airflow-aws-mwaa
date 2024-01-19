import pyspark
import argparse

from pandas import DataFrame as PdDataFrame
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

SPARK_LOCAL_CONFIGS: dict[str, str] = {
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


def run(spark: SparkSession):
    data = [
        ("James","","Smith","36636","M",3000),
        ("Michael","Rose","","40288","M",4000),
        ("Robert","","Williams","42114","M",4000),
        ("Maria","Anne","Jones","39192","F",4000),
        ("Jen","Mary","Brown","","F",-1)
    ]

    schema = StructType([ 
        StructField("firstname",StringType(),True),
        StructField("middlename",StringType(),True),
        StructField("lastname",StringType(),True),
        StructField("id", StringType(), True),
        StructField("gender", StringType(), True),
        StructField("salary", IntegerType(), True)
    ])
    
    df: DataFrame = spark.createDataFrame(data=data,schema=schema)
    df.printSchema()
    df.show(truncate=False)

    pd: PdDataFrame = df.toPandas()
    print(pd)


def setup_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--local', help="Allow PySpark to Download Spark Dependencies", default=False, action="store_true"
    )
    return parser.parse_args()

  

if __name__ == "__main__":
    args = setup_args()
    spark: SparkSession = get_spark_session(is_local=args.local)
    run(spark)
    spark.stop()
