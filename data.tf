data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_elb_service_account" "main" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  # run packer build before terraform apply
  owners = [data.aws_caller_identity.current.account_id]

  filter {
    name   = "name"
    values = ["learn-packer-linux-aws-redis-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}