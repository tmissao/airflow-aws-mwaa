FROM public.ecr.aws/emr-serverless/spark/emr-7.0.0:latest
USER root

ARG PACKAGES="\
org.postgresql:postgresql:42.7.1,\
mysql:mysql-connector-java:8.0.33\
"

RUN spark-submit run-example --packages $PACKAGES --deploy-mode=client --master=local[1] SparkPi
RUN mv /root/.ivy2/jars/* /usr/lib/spark/jars/

USER hadoop:hadoop
