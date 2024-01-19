resource "aws_key_pair" "this" {
  key_name   = "demo-key"
  public_key = file("${path.module}/keys/key.pub")
  tags = var.tags
}

data "aws_ami" "this" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# data "template_file" "init" {
#   template = file("${path.module}/scripts/init.cfg")
# }

# data "template_file" "shell-script" {
#   template = file("${path.module}/scripts/setup.sh")
#   vars = {
#     DOCKER_FILE = base64decode(file("${path.module}/Dockerfile"))
#     KAFKA_CLIENT_PROPERTIES = base64encode((templatefile("${path.module}/templates/kafka-client.properties", {})))
#   }
# }

# data "template_cloudinit_config" "config" {
#   gzip = true
#   base64_encode = true
#   part {
#     filename = "init.cfg"
#     content_type = "text/cloud-config"
#     content = data.template_file.init.rendered
#   }
#   part {
#     content_type = "text/x-shellscript"
#     content = data.template_file.shell-script.rendered
#   }
# }

# resource "aws_instance" "this" {
#   ami           = data.aws_ami.this.id
#   instance_type = "t3.micro"
#   key_name      = aws_key_pair.this.key_name
#   subnet_id     = one(module.vpc.public_subnets)
#   vpc_security_group_ids = [aws_security_group.demo_emr_vm.id] 
#   user_data_base64 = data.template_cloudinit_config.config.rendered
#   user_data_replace_on_change = true
#   associate_public_ip_address = true
#   iam_instance_profile = aws_iam_instance_profile.instance_profile.name
#   volume_tags = merge(
#     var.tags,
#     { Name = "emr-demo"}
#   )
#   tags = merge(
#     var.tags,
#     { Name = "emr-demo"}
#   )
# }