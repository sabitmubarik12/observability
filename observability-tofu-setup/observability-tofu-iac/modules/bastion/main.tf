
resource "aws_security_group" "bastion_sg" {
  name        = "${var.environment}-bastion-sg"
  description = "Security Group for Bastion"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed IP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Egress to allow SSH to observability EC2
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-bastion-sg"
  }
}

resource "tls_private_key" "bastion_key" {
  count = var.key_pair_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "bastion_keypair" {
  count      = var.key_pair_name == "" ? 1 : 0
  key_name   = "${var.environment}-bastion-key"
  public_key = tls_private_key.bastion_key[0].public_key_openssh
}

resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type  = var.instance_type["bastion"]
  subnet_id              = element(var.public_subnets, 0)
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  key_name = var.key_pair_name == "" ? aws_key_pair.bastion_keypair[0].key_name : var.key_pair_name

  associate_public_ip_address = true

  tags = {
    Name = "${var.environment}-bastion"
  }
}

