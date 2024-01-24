resource "random_integer" "this" {
  min = 10000
  max = 50000
  keepers = { s3_name = var.s3.name }
}

resource "aws_s3_bucket" "this" {
  bucket =  "${var.s3.name}-${random_integer.this.result}"
  force_destroy = true
  tags = var.tags
}

resource "aws_s3_object" "emr_data" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
  key    = "data/"
}

resource "aws_s3_object" "jar_postgres" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
  key    = "jars/postgresql-42.7.1.jar"
  source = "../python/jars/postgresql-42.7.1.jar"
}

resource "aws_s3_object" "pyspark_simple_script" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
  key    = "scripts/simple.py"
  source = "../python/scripts/simple.py"
}

resource "aws_s3_object" "pyspark_jdbc_script" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
  key    = "scripts/jdbc.py"
  source = "../python/scripts/jdbc.py"
}

resource "aws_s3_object" "pyspark_s3_script" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
  key    = "scripts/s3.py"
  source = "../python/scripts/s3.py"
}

resource "aws_s3_object" "cities_csv" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
  key    = "data/cities.csv"
  source = "../python/data/cities.csv"
}

resource "aws_emr_studio" "this" {
  auth_mode                   = var.emr_studio.auth_mode
  default_s3_location         = "s3://${aws_s3_bucket.this.bucket}/data"
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

resource "aws_emrserverless_application" "basic" {
  name          = "basic-application"
  release_label = "emr-7.0.0"
  type          = "spark"
  auto_start_configuration {
    enabled = true
  }
  auto_stop_configuration  {
    enabled = true
    idle_timeout_minutes = 5
  }
  maximum_capacity {
    cpu = "400 vCPU"
    memory = "3000 GB"
  }
  network_configuration {
    subnet_ids = module.vpc.private_subnets
    security_group_ids = [aws_security_group.emr_workspace.id]
  }
  tags = var.tags
}

resource "aws_emrserverless_application" "custom_image" {
  name          = "custom-image"
  release_label = "emr-7.0.0"
  type          = "spark"
  auto_start_configuration {
    enabled = true
  }
  auto_stop_configuration  {
    enabled = true
    idle_timeout_minutes = 5
  }
  maximum_capacity {
    cpu = "400 vCPU"
    memory = "3000 GB"
  }
  network_configuration {
    subnet_ids = module.vpc.private_subnets
    security_group_ids = [aws_security_group.emr_workspace.id]
  }
  image_configuration {
    image_uri = "${aws_ecr_repository.emr.repository_url}:latest"
  }
  tags = var.tags
  depends_on = [ null_resource.build_custom_image ]
}

resource "random_password" "postgres" {
  length           = 32
  special          = false
}

resource "null_resource" "build_custom_image" {
  triggers = {
    DOCKERFILE_HASH = filemd5("../Dockerfile")
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

resource "aws_sfn_state_machine" "this" {
  name     = "demo-emr-sfn"
  role_arn = aws_iam_role.sfn.arn
  definition = templatefile("./templates/step-function-pipeline.json", {
    EMR_SERVERLESS_APPLICATION = aws_emrserverless_application.basic.id
    EMR_SERVERLESS_EXECUTOR_ROLE = aws_iam_role.emr_serverless.arn
    BUCKET_NAME = aws_s3_bucket.this.bucket
    POSTGRES_HOST = aws_instance.this.public_ip
    POSTGRES_USER = var.postgres_user
    POSTGRES_PASSWORD = random_password.postgres.result
  })
}

resource "aws_scheduler_schedule" "this" {
  name = "demo-emr-schedule"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "cron(*/5 * * * ? *)"
  target {
    arn      = aws_sfn_state_machine.this.arn
    role_arn = aws_iam_role.eventbridge.arn
  }
}