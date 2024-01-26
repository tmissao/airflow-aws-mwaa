resource "aws_sfn_state_machine" "sfn_simple" {
  name     = "demo-emr-sfn-simple"
  role_arn = aws_iam_role.sfn.arn
  definition = templatefile("./templates/sfn-simple.json", {
    EMR_SERVERLESS_APPLICATION = aws_emrserverless_application.custom_image.id
    EMR_SERVERLESS_EXECUTOR_ROLE = aws_iam_role.emr_serverless.arn
    BUCKET_NAME = aws_s3_bucket.this.bucket
  })
}

resource "aws_scheduler_schedule" "sfn_simple" {
  name = "demo-emr-sfn-simple"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "cron(*/5 * * * ? *)"
  target {
    arn      = aws_sfn_state_machine.sfn_simple.arn
    role_arn = aws_iam_role.eventbridge.arn
  }
}

resource "aws_sfn_state_machine" "sfn_jdbc_maven" {
  name     = "demo-emr-sfn-jdbc-maven"
  role_arn = aws_iam_role.sfn.arn
  definition = templatefile("./templates/sfn-jdbc-maven.json", {
    EMR_SERVERLESS_APPLICATION = aws_emrserverless_application.basic.id
    EMR_SERVERLESS_EXECUTOR_ROLE = aws_iam_role.emr_serverless.arn
    BUCKET_NAME = aws_s3_bucket.this.bucket
    POSTGRES_HOST = aws_instance.this.public_ip
    POSTGRES_USER = var.postgres_user
    POSTGRES_PASSWORD = random_password.postgres.result
  })
}

resource "aws_scheduler_schedule" "sfn_jdbc_maven" {
  name = "demo-sfn-jdbc-maven-schedule"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "cron(*/5 * * * ? *)"
  target {
    arn      = aws_sfn_state_machine.sfn_jdbc_maven.arn
    role_arn = aws_iam_role.eventbridge.arn
  }
}

resource "aws_sfn_state_machine" "sfn_jdbc_s3" {
  name     = "demo-emr-sfn-jdbc-s3"
  role_arn = aws_iam_role.sfn.arn
  definition = templatefile("./templates/sfn-jdbc-s3.json", {
    EMR_SERVERLESS_APPLICATION = aws_emrserverless_application.basic.id
    EMR_SERVERLESS_EXECUTOR_ROLE = aws_iam_role.emr_serverless.arn
    BUCKET_NAME = aws_s3_bucket.this.bucket
    POSTGRES_HOST = aws_instance.this.public_ip
    POSTGRES_USER = var.postgres_user
    POSTGRES_PASSWORD = random_password.postgres.result
  })
}

resource "aws_scheduler_schedule" "sfn_jdbc_s3" {
  name = "demo-sfn-jdbc-s3-schedule"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "cron(*/5 * * * ? *)"
  target {
    arn      = aws_sfn_state_machine.sfn_jdbc_s3.arn
    role_arn = aws_iam_role.eventbridge.arn
  }
}

resource "aws_sfn_state_machine" "sfn_jdbc_custom_image" {
  name     = "demo-emr-sfn-jdbc-custom-image"
  role_arn = aws_iam_role.sfn.arn
  definition = templatefile("./templates/sfn-jdbc-custom-image.json", {
    EMR_SERVERLESS_APPLICATION = aws_emrserverless_application.custom_image.id
    EMR_SERVERLESS_EXECUTOR_ROLE = aws_iam_role.emr_serverless.arn
    BUCKET_NAME = aws_s3_bucket.this.bucket
    POSTGRES_HOST = aws_instance.this.public_ip
    POSTGRES_USER = var.postgres_user
    POSTGRES_PASSWORD = random_password.postgres.result
  })
}

resource "aws_scheduler_schedule" "sfn_jdbc_custom_image" {
  name = "demo-sfn-jdbc-custom-image"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "cron(*/5 * * * ? *)"
  target {
    arn      = aws_sfn_state_machine.sfn_jdbc_custom_image.arn
    role_arn = aws_iam_role.eventbridge.arn
  }
}

resource "aws_sfn_state_machine" "sfn_s3" {
  name     = "demo-emr-sfn-s3"
  role_arn = aws_iam_role.sfn.arn
  definition = templatefile("./templates/sfn-s3.json", {
    EMR_SERVERLESS_APPLICATION = aws_emrserverless_application.custom_image.id
    EMR_SERVERLESS_EXECUTOR_ROLE = aws_iam_role.emr_serverless.arn
    BUCKET_NAME = aws_s3_bucket.this.bucket
    AWS_REGION = var.aws_region
  })
}

resource "aws_scheduler_schedule" "sfn_s3" {
  name = "demo-emr-sfn-s3"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "cron(*/5 * * * ? *)"
  target {
    arn      = aws_sfn_state_machine.sfn_s3.arn
    role_arn = aws_iam_role.eventbridge.arn
  }
}