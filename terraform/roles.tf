data "aws_iam_policy_document" "emr_studio" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["elasticmapreduce.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "emr_studio" {
  name               = "EmrStudio"
  assume_role_policy = data.aws_iam_policy_document.emr_studio.json
  managed_policy_arns = var.emr_studio.policies
  tags = var.tags
}

data "aws_iam_policy_document" "emr_serverless" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["emr-serverless.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "emr_serverless_policy" {
  statement {
    sid = "GlueCreateAndReadDataCatalog"
    actions = [
      "glue:GetDatabase",
      "glue:CreateDatabase",
      "glue:GetDataBases",
      "glue:CreateTable",
      "glue:GetTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:CreatePartition",
      "glue:BatchCreatePartition",
      "glue:GetUserDefinedFunctions"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid = "ReadAccessForEMRSamples"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::*.elasticmapreduce",
      "arn:aws:s3:::*.elasticmapreduce/*"
    ]
  }
  statement {
    sid = "FullAccessToOutputBucket"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "emr_serverless" {
  name               = "EmrServerlessExecutor"
  policy = data.aws_iam_policy_document.emr_serverless_policy.json
  tags = var.tags
}

resource "aws_iam_role" "emr_serverless" {
  name               = "EmrServerlessExecutor"
  assume_role_policy = data.aws_iam_policy_document.emr_serverless.json
  managed_policy_arns = [ aws_iam_policy.emr_serverless.arn ]
  tags = var.tags
}

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    sid    = "EMR Serverless Custom Image Support"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = [
        "emr-serverless.amazonaws.com"
      ]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
    ]
  }
}

resource "aws_ecr_repository_policy" "ecr_policy" {
  repository = aws_ecr_repository.emr.name
  policy     = data.aws_iam_policy_document.ecr_policy.json
}

data "aws_iam_policy_document" "airflow_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = [
        "airflow.amazonaws.com",
        "airflow-env.amazonaws.com"
      ]
    }
  }
}


data "aws_iam_policy_document" "airflow_policy" {
  statement {
    actions = [
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:List*"
    ]
    resources = [
      aws_s3_bucket.airflow.arn,
      "${aws_s3_bucket.airflow.arn}/*"
    ]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:airflow-${var.airflow.name}-*"
    ]
  }
  statement {
    actions = [
      "logs:DescribeLogGroups",
      "s3:GetAccountPublicAccessBlock",
      "cloudwatch:PutMetricData"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage"
    ]
    resources = [
      "arn:aws:sqs:${var.aws_region}:*:airflow-celery-*"
    ]
  }
  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt"
    ]
    not_resources = [
      "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
    ]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values = [
        "sqs.${var.aws_region}.amazonaws.com",
      ]
    }
  }
  # Custom Permissions
  statement {
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameters",
			"ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/airflow/*"
    ]
  }
  statement {
    actions = [
      "emr-serverless:StartApplication",
      "emr-serverless:GetApplication",
      "emr-serverless:StopApplication",
      "emr-serverless:StartJobRun",
      "emr-serverless:CreateApplication",
      "emr-serverless:GetJobRun",
      "emr-serverless:CancelJobRun",
      "emr-serverless:TagResource"
    ]
    resources = [
      "arn:aws:emr-serverless:${var.aws_region}:${data.aws_caller_identity.current.account_id}:/*"
    ]
  }
  statement {
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.emr_serverless.arn
    ]
  }
   statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [
      aws_ecr_repository.emr.arn
    ]
  }
  statement {
    actions = [
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:List*",
      "s3:PutObject*",
    ]
    resources = [
      aws_s3_bucket.emr.arn,
      "${aws_s3_bucket.emr.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "airflow" {
  name               = "AirflowExecutor"
  policy = data.aws_iam_policy_document.airflow_policy.json
  tags = var.tags
}

resource "aws_iam_role" "airflow" {
  name               = "AirflowExecutor"
  assume_role_policy = data.aws_iam_policy_document.airflow_trust_policy.json
  managed_policy_arns = [aws_iam_policy.airflow.arn]
  tags = var.tags
}