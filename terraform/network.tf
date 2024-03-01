module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = var.vpc.name 
  cidr = var.vpc.cidr 
  azs  = var.vpc.azs 
  private_subnets = var.vpc.private_subnets 
  public_subnets  = var.vpc.public_subnets 
  enable_nat_gateway = var.vpc.enable_nat_gateway 
  enable_vpn_gateway = var.vpc.enable_vpn_gateway 
  single_nat_gateway = var.vpc.single_nat_gateway
  one_nat_gateway_per_az = var.vpc.one_nat_gateway_per_az
  map_public_ip_on_launch = true
  tags = var.tags
}

resource "aws_vpc_endpoint" "this" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.us-west-2.s3"
  tags = merge(
    { "Name" = "demo-emr-vpc-s3-endpoint" },
    var.tags
  )
  depends_on = [module.vpc]
}

resource "aws_vpc_endpoint_route_table_association" "public" {
  route_table_id  = one(module.vpc.public_route_table_ids)
  vpc_endpoint_id = aws_vpc_endpoint.this.id
  depends_on      = [aws_vpc_endpoint.this]
}

resource "aws_vpc_endpoint_route_table_association" "private" {
  route_table_id  = one(module.vpc.private_route_table_ids)
  vpc_endpoint_id = aws_vpc_endpoint.this.id
  depends_on      = [aws_vpc_endpoint.this]
}

resource "aws_security_group" "emr_engine" {
  name        = "EmrEngineSecurityGroup"
  vpc_id      = module.vpc.vpc_id
  tags = merge(
    { "Name" = "EmrEngineSecurityGroup" },
    var.tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "allow_workspace_communication" {
  security_group_id = aws_security_group.emr_engine.id
  from_port         = 18888
  to_port           = 18888
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.emr_workspace.id
}

resource "aws_security_group" "emr_workspace" {
  name        = "EmrWorkspaceSecurityGroup"
  vpc_id      = module.vpc.vpc_id
  tags = merge(
    { "Name" = "EmrWorkspaceSecurityGroup" },
    var.tags
  )
}

resource "aws_vpc_security_group_egress_rule" "allow_egress_postgres" {
  security_group_id = aws_security_group.emr_workspace.id
  description = "Allow Postgres Egress"
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_egress_mssql" {
  security_group_id = aws_security_group.emr_workspace.id
  description = "Allow Postgres Egress"
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 1433
  to_port     = 1433
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_egress_https" {
  security_group_id = aws_security_group.emr_workspace.id
  description = "Allow Htttps Egress"
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_egress_emr_engine" {
  security_group_id = aws_security_group.emr_workspace.id
  description = "Allow EMR Engine Egress"
  referenced_security_group_id   = aws_security_group.emr_engine.id
  from_port   = 18888
  to_port     = 18888
  ip_protocol = "tcp"
}

resource "aws_security_group" "demo_emr_vm" {
  name        = "Demo VM"
  description = "Allow Connection with Demo EMR VM"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    { "Name" = "Demo EMR VM" },
    var.tags
  )
}

resource "aws_security_group" "airflow" {
  name        = "Airflow SG"
  description = "Allow Connection with Airflow"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    { "Name" = "Airflow SG" },
    var.tags
  )
}