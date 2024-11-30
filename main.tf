# VPC
resource "aws_vpc" "app_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.app_name}-public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.private_subnet_cidr_block
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.app_name}-private-subnet"
  }
}

# Security Group
resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-sg"
  description = "Allow SSH, HTTP, and HTTPS traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Generate ED25519 SSH Key Pair and Save Private Key Locally
resource "tls_private_key" "app_key" {
  algorithm = "ED25519"
}

# Save the private key to a file in the root folder of the project
resource "local_file" "private_key" {
  content  = tls_private_key.app_key.private_key_pem
  filename = "${path.module}/petpoha-ssh-key.pem"  # Saves the private key in the root folder
}

# AWS Key Pair to use the generated key
resource "aws_key_pair" "app_key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.app_key.public_key_openssh
}

# EC2 Instance
resource "aws_instance" "app_instance" {
  ami                  = data.aws_ami.latest_amazon_linux.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name             = aws_key_pair.app_key_pair.key_name  # Use the created key pair
  user_data            = <<-EOF
                          #!/bin/bash
                          sudo apt-get update -y
                          sudo apt-get install -y nginx
                        EOF

  tags = {
    Name = "${var.app_name}-instance"
  }
}

# AMI Data Source
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
