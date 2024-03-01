resource "random_integer" "this" {
  min = 10000
  max = 50000
  keepers = { s3_name = var.s3_emr.name }
}

resource "aws_s3_bucket" "emr" {
  bucket =  "${var.s3_emr.name}-${random_integer.this.result}"
  force_destroy = true
  tags = var.tags
}

resource "aws_s3_bucket" "airflow" {
  bucket =  "${var.s3_airflow.name}-${random_integer.this.result}"
  force_destroy = true
  tags = var.tags
}

resource "aws_s3_object" "airflow_dags" {
  bucket = aws_s3_bucket.airflow.id
  acl    = "private"
  key    = "dags/"
}

resource "aws_s3_bucket_versioning" "airflow" {
  bucket = aws_s3_bucket.airflow.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "dags" {
  for_each = var.airflow_dags
  bucket = aws_s3_bucket.airflow.id
  acl    = "private"
  key    = "dags/${each.value.s3_filename}"
  source = each.value.source
  etag = filemd5(each.value.source)
}

resource "aws_s3_object" "python_requirements" {
  bucket = aws_s3_bucket.airflow.id
  acl    = "private"
  key    = "requirements.txt"
  source = "../airflow/requirements.txt"
  etag = filemd5("../airflow/requirements.txt")
}

resource "aws_s3_object" "emr_data" {
  bucket = aws_s3_bucket.emr.id
  acl    = "private"
  key    = "data/"
}

resource "aws_s3_object" "emr_log" {
  bucket = aws_s3_bucket.emr.id
  acl    = "private"
  key    = "logs/"
}

resource "aws_s3_object" "jar_postgres" {
  bucket = aws_s3_bucket.emr.id
  acl    = "private"
  key    = "jars/postgresql-42.7.1.jar"
  source = "../python/jars/postgresql-42.7.1.jar"
}

resource "aws_s3_object" "pyspark_simple_script" {
  bucket = aws_s3_bucket.emr.id
  acl    = "private"
  key    = "scripts/simple.py"
  source = "../python/scripts/simple.py"
}

resource "aws_s3_object" "pyspark_jdbc_script" {
  bucket = aws_s3_bucket.emr.id
  acl    = "private"
  key    = "scripts/jdbc.py"
  source = "../python/scripts/jdbc.py"
}

resource "aws_s3_object" "pyspark_s3_script" {
  bucket = aws_s3_bucket.emr.id
  acl    = "private"
  key    = "scripts/s3.py"
  source = "../python/scripts/s3.py"
}

resource "aws_s3_object" "cities_csv" {
  bucket = aws_s3_bucket.emr.id
  acl    = "private"
  key    = "data/cities.csv"
  source = "../python/data/cities.csv"
}

resource "aws_emr_studio" "this" {
  auth_mode                   = var.emr_studio.auth_mode
  default_s3_location         = "s3://${aws_s3_bucket.emr.bucket}/data"
  engine_security_group_id    = aws_security_group.emr_engine.id
  name                        = var.emr_studio.name
  service_role                = aws_iam_role.emr_studio.arn
  subnet_ids                  = module.vpc.private_subnets
  vpc_id                      = module.vpc.vpc_id
  workspace_security_group_id = aws_security_group.emr_workspace.id
}

resource "aws_ecr_repository" "emr" {
  name                 = "emr-custom"
  image_tag_mutability = "MUTABLE"
  force_delete = true
  tags = var.tags
}
resource "random_password" "postgres" {
  length           = 32
  special          = false
}

resource "null_resource" "build_custom_image" {
  triggers = {
    DOCKERFILE_HASH = filemd5("./templates/Dockerfile")
  }
  provisioner "local-exec" {
    command = "/bin/bash ./scripts/build-image.sh"
    environment = {
      ECR_REGISTRY_REGION = var.aws_region
      ECR_REGISTRY_URL    = aws_ecr_repository.emr.repository_url
      TAG = "latest"
      DOCKERFILE_PATH   = "./Dockerfile"
    }
  }
}

resource "aws_mwaa_environment" "this" {
  name               = var.airflow.name
  airflow_configuration_options = var.airflow.configurations
  airflow_version = var.airflow.version
  dag_s3_path        = aws_s3_object.airflow_dags.id
  environment_class = var.airflow.environment_class
  execution_role_arn = aws_iam_role.airflow.arn
  max_workers = var.airflow.max_workers
  min_workers = var.airflow.min_workers
  requirements_s3_path = aws_s3_object.python_requirements.id
  requirements_s3_object_version = aws_s3_object.python_requirements.version_id
  schedulers = var.airflow.schedulers
  source_bucket_arn = aws_s3_bucket.airflow.arn
  webserver_access_mode = var.airflow.webserver_access_mode
  weekly_maintenance_window_start = var.airflow.weekly_maintenance_window_start
  network_configuration {
    security_group_ids = [aws_security_group.airflow.id]
    subnet_ids         = slice(module.vpc.private_subnets,0,2)
  }
  logging_configuration {
    dag_processing_logs {
      enabled   = var.airflow.logging_configuration.dag_processing_logs.enabled 
      log_level = var.airflow.logging_configuration.dag_processing_logs.log_level 
    }
    scheduler_logs {
      enabled   = var.airflow.logging_configuration.scheduler_logs.enabled 
      log_level = var.airflow.logging_configuration.scheduler_logs.log_level 
    }
    task_logs {
      enabled   = var.airflow.logging_configuration.task_logs.enabled 
      log_level = var.airflow.logging_configuration.task_logs.log_level 
    }
    webserver_logs {
      enabled   = var.airflow.logging_configuration.webserver_logs.enabled 
      log_level = var.airflow.logging_configuration.webserver_logs.log_level 
    }
    worker_logs {
      enabled   = var.airflow.logging_configuration.worker_logs.enabled 
      log_level = var.airflow.logging_configuration.worker_logs.log_level 
    }
  }
}