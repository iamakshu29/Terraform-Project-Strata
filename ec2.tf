data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  subnet_map = {
    public  = aws_subnet.strata_public_subnet
    private = aws_subnet.strata_private_subnet
  }
}

resource "aws_instance" "strata_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.aws_bastian_instance.instance_type
  subnet_id                   = aws_subnet.strata_public_subnet[var.aws_bastian_instance.subnet_az].id
  associate_public_ip_address = var.aws_bastian_instance.associate_public_ip_address
  vpc_security_group_ids      = [aws_security_group.strata_sg["bastion"].id]
  # SSM Session Manager — no SSH key or open port 22 needed
  iam_instance_profile = aws_iam_instance_profile.strata.name

  # Wait for IAM propagation before launching — avoids race condition on first apply
  depends_on = [aws_iam_role_policy_attachment.strata_ssm_core]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    kms_key_id            = aws_kms_key.strata.arn
    delete_on_termination = true
  }

  tags = merge({ Name = "strata-bastion" }, local.tags)

  timeouts {
    create = "15m"
  }
}

resource "aws_ebs_volume" "strata_data_vol" {
  availability_zone = var.aws_bastian_instance.subnet_az
  size              = var.aws_bastian_instance.ebs_size
  encrypted         = true
  kms_key_id        = aws_kms_key.strata.arn

  tags = merge({ Name = "strata-bastion-data-vol" }, local.tags)
}

resource "aws_volume_attachment" "strata_vol_att" {
  device_name = "/dev/sdh" # Linux device mounting path
  volume_id   = aws_ebs_volume.strata_data_vol.id
  instance_id = aws_instance.strata_server.id
}