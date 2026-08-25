resource "aws_instance" "strata_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.aws_bastian_instance.instance_type
  subnet_id                   = aws_subnet.strata_public_subnet[var.aws_bastian_instance.subnet_az].id
  associate_public_ip_address = var.aws_bastian_instance.associate_public_ip_address
  vpc_security_group_ids      = [aws_security_group.strata_sg["bastion"].id]
  iam_instance_profile        = aws_iam_instance_profile.strata.name

  depends_on = [aws_iam_role_policy_attachment.strata_ssm_core]

  # IMDSv2 required — SSM agent, cloud-init, and all AWS SDKs on this instance must use token-based IMDS
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Ensures SSM agent is running — Ubuntu 22.04 snap installs it but doesn't always start it
  user_data = <<-EOF
    #!/bin/bash
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.aws_bastian_instance.volume_size
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = aws_kms_key.strata.arn
  }

  tags = merge({ Name = "strata-bastion" }, local.tags)

  timeouts {
    create = "15m"
  }
}
