variable "vpc" {
  default = {
    name = "demo-emr-vpc"
    cidr = "10.0.0.0/16"
    azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
    enable_nat_gateway = true
    enable_vpn_gateway = false
    single_nat_gateway = true
    one_nat_gateway_per_az = false
  }
}

variable "aws_region" {
  default = "us-west-2"
}

variable "s3" {
  default = {
    name = "demo-emr"
  }
}

variable "emr_studio" {
  default = {
    auth_mode = "IAM"
    name = "demo-studio"
    policies = [
      "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceEditorsRole",
      "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    ]
  }
}

variable "postgres_user" {
  default = "postgres"
}

variable "tags" {
  type = map(string)
  default = {
    terraform       = "true"
    project         = "demo-emr"
    owner           = "missao"
  }
}