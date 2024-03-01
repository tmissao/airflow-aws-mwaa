data "aws_caller_identity" "current" {}

variable "vpc" {
  default = {
    name = "demo-airflow-vpc"
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

variable "s3_emr" {
  default = {
    name = "demo-emr"
  }
}

variable "s3_airflow" {
  default = {
    name = "demo-airflow"
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

variable "airflow_secret_backend_prefix" {
  default = {
    variables = "/airflow/variables"
    connections = "/airflow/connections"
    config = "/airflow/config"
  }
}

variable "airflow" {
  default = {
    name = "demo"
    version = "2.8.1"
    environment_class = "mw1.small"
    max_workers = 1
    min_workers = 1
    schedulers = 2
    webserver_access_mode = "PUBLIC_ONLY"
    weekly_maintenance_window_start = "SAT:04:00"
    configurations = {
      "secrets.backend" = "airflow.providers.amazon.aws.secrets.systems_manager.SystemsManagerParameterStoreBackend"
      "secrets.backend_kwargs" = "{\"connections_prefix\": \"airflow/connections\", \"variables_prefix\": \"airflow/variables\", \"config_prefix\": \"airflow/config\"}"
    }
    logging_configuration = {
      dag_processing_logs = {
        enabled = true
        log_level = "INFO"
      }
      scheduler_logs = {
        enabled = true
        log_level = "INFO"
      }
      task_logs = {
        enabled = true
        log_level = "INFO"
      }
      webserver_logs = {
        enabled = true
        log_level = "INFO"
      }
      worker_logs = {
        enabled = true
        log_level = "INFO"
      }
    }
  }
}

variable "airflow_dags" {
  default = {
    sleep = {
      s3_filename = "sleep.py"
      source = "../airflow/dags/sleep.py"
    }
    secret = {
      s3_filename = "secrets.py"
      source = "../airflow/dags/secrets.py"
    }
    emr-serverless-jdbc = {
      s3_filename = "emr-serverless-jdbc.py"
      source = "../airflow/dags/emr-serverless-jdbc.py"
    }
    emr-serverless-s3 = {
      s3_filename = "emr-serverless-s3.py"
      source = "../airflow/dags/emr-serverless-s3.py"
    }
    s3-test = {
      s3_filename = "s3.py"
      source = "../airflow/dags/s3.py"
    }
  }
}

variable "tags" {
  type = map(string)
  default = {
    terraform       = "true"
    project         = "demo-emr"
    owner           = "missao"
  }
}