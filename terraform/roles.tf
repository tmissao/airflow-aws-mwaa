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
      identifiers = ["emr-serverless.amazonaws.com"]
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

data "aws_iam_policy_document" "demo_emr_vm" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions   = ["sts:AssumeRole"]
  }
}

data aws_iam_policy_document "demo_emr_vm_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [aws_ecr_repository.emr.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
			"emr-serverless:StartJobRun",
			"emr-serverless:StartApplication",
    ]
    resources = [
      aws_emrserverless_application.basic.arn,
      aws_emrserverless_application.custom_image.arn
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
}

resource "aws_iam_role" "demo_emr_vm" {
  name = "allow_ec2_to_push_to_ecr"
  assume_role_policy = "${data.aws_iam_policy_document.demo_emr_vm.json}"
}

resource "aws_iam_role_policy" "demo_emr_vm" {
  name       = "allow_ec2_to_push_to_ecr"
  role       = aws_iam_role.demo_emr_vm.name
  policy = data.aws_iam_policy_document.demo_emr_vm_policy.json
}

resource "aws_iam_instance_profile" "demo_emr_vm" {
  name = "allow_ec2_to_push_to_ecr"
  role = aws_iam_role.demo_emr_vm.name
}