resource "aws_ssm_parameter" "aws-region" {
  name  = "${var.airflow_secret_backend_prefix.variables}/aws-region"
  type  = "String"
  value = var.aws_region
}

resource "aws_ssm_parameter" "private_subnets_ids" {
  name  = "${var.airflow_secret_backend_prefix.variables}/private-subnets-ids"
  type  = "StringList"
  value = join(",", module.vpc.private_subnets)
}

resource "aws_ssm_parameter" "emr_workspace_securitygroup_ids" {
  name  = "${var.airflow_secret_backend_prefix.variables}/emr-workspace-sg-id"
  type  = "String"
  value = aws_security_group.emr_workspace.id
}

resource "aws_ssm_parameter" "emr_executor_role_arn" {
  name  = "${var.airflow_secret_backend_prefix.variables}/emr-executor-role-arn"
  type  = "String"
  value = aws_iam_role.emr_serverless.arn
}

resource "aws_ssm_parameter" "emr_custom_image" {
  name  = "${var.airflow_secret_backend_prefix.variables}/emr-custom-image-tag"
  type  = "String"
  value = "${aws_ecr_repository.emr.repository_url}:latest"
}

resource "aws_ssm_parameter" "emr_s3_bucket_name" {
  name  = "${var.airflow_secret_backend_prefix.variables}/emr-s3-bucket-name"
  type  = "String"
  value = aws_s3_bucket.emr.bucket
}

resource "aws_ssm_parameter" "emr_s3_log_directory" {
  name  = "${var.airflow_secret_backend_prefix.variables}/emr-s3-log-directory"
  type  = "String"
  value = "s3://${aws_s3_bucket.emr.bucket}/${aws_s3_object.emr_log.id}"
}

resource "aws_ssm_parameter" "emr_s3_scripts_simple" {
  name  = "${var.airflow_secret_backend_prefix.variables}/emr-s3-scripts-simple"
  type  = "String"
  value = "s3://${aws_s3_bucket.emr.bucket}/${aws_s3_object.pyspark_simple_script.id}"
}

resource "aws_ssm_parameter" "emr_s3_scripts_jdbc" {
  name  = "${var.airflow_secret_backend_prefix.variables}/emr-s3-scripts-jdbc"
  type  = "String"
  value = "s3://${aws_s3_bucket.emr.bucket}/${aws_s3_object.pyspark_jdbc_script.id}"
}

resource "aws_ssm_parameter" "emr_s3_script_s3" {
  name  = "${var.airflow_secret_backend_prefix.variables}/emr-s3-scripts-s3"
  type  = "String"
  value = "s3://${aws_s3_bucket.emr.bucket}/${aws_s3_object.pyspark_s3_script.id}"
}

resource "aws_ssm_parameter" "emr_s3_jars_postgres" {
  name  = "${var.airflow_secret_backend_prefix.variables}/emr-s3-jars-postgres"
  type  = "String"
  value = "s3://${aws_s3_bucket.emr.bucket}/${aws_s3_object.jar_postgres.id}"
}

resource "aws_ssm_parameter" "postgres_hostname" {
  name  = "${var.airflow_secret_backend_prefix.variables}/postgres-hostname"
  type  = "String"
  value = aws_instance.this.public_ip
}

resource "aws_ssm_parameter" "postgres_user" {
  name  = "${var.airflow_secret_backend_prefix.variables}/postgres-user"
  type  = "String"
  value = var.postgres_user
}

resource "aws_ssm_parameter" "postgres_password" {
  name  = "${var.airflow_secret_backend_prefix.variables}/postgres-password"
  type  = "SecureString"
  value = random_password.postgres.result
}