resource "aws_security_group" "observability_sg" {
  name        = "${var.environment}-observability-sg"
  description = "Security group for observability EC2"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB on 80"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  ingress {
    description       = "Allow Grafana from ALB"
    from_port         = 3000
    to_port           = 3000
    protocol          = "tcp"
    security_groups   = [var.alb_sg_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow traffic from Bastion on 22"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-observability-sg"
  }
}

# If no key_pair_name is supplied, create a new key pair
resource "tls_private_key" "observability_key" {
  count = var.key_pair_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "observability_keypair" {
  count     = var.key_pair_name == "" ? 1 : 0
  key_name  = "${var.environment}-observability-key"
  public_key = tls_private_key.observability_key[0].public_key_openssh
}

resource "aws_instance" "observability_ec2" {
  ami           = var.ami_id
  instance_type  = var.instance_type["web"]
  subnet_id     = element(var.private_subnets, 0)  # put in first private subnet
  vpc_security_group_ids = [aws_security_group.observability_sg.id]

  key_name = var.key_pair_name == "" ? aws_key_pair.observability_keypair[0].key_name : var.key_pair_name

  root_block_device {
    volume_size = 150  # Specify the desired volume size in GB
    volume_type = "gp3"  # Optional: Specify volume type (gp2, gp3, io1, etc.)
    delete_on_termination = true
  }

  tags = {
    Name = "${var.environment}-observability-instance"
  }

  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    # Install observability or other required software...
    # Example:
    amazon-linux-extras install epel -y
    yum install java-11-amazon-corretto -y
    echo "observability installed" > /tmp/observability_install.txt
  EOT
}

