# VPC
resource "aws_vpc" "app_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }

  tags = {
    Name = "${var.app_name}-public-rt"
  }
}

# Associate Public Subnet with the Public Route Table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
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

resource "local_file" "private_key" {
  content  = tls_private_key.app_key.private_key_pem
  filename = "${path.module}/petpoha-ssh-key.pem"
}

# AWS Key Pair
resource "aws_key_pair" "app_key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.app_key.public_key_openssh
}

# IAM Role for EC2 instance to access ECR
resource "aws_iam_role" "ec2_role" {
  name = "${var.app_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AmazonEC2ContainerRegistryReadOnly Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Instance Profile to associate with EC2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.app_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Data Source for Latest Amazon Linux AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance with IAM Role attached
resource "aws_instance" "app_instance" {
  ami                  = data.aws_ami.latest_amazon_linux.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name             = aws_key_pair.app_key_pair.key_name
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
  #!/bin/bash
  sudo apt-get update -y
  sudo apt-get install -y nginx docker.io

  # Start Docker and enable on boot
  sudo systemctl start docker
  sudo systemctl enable docker

  # Log in to ECR and pull the Docker image
  $(aws ecr get-login --no-include-email --region ap-southeast-1)

  # Run the application container
  docker run -d -p 3000:80 --name petpoha-web 796973505325.dkr.ecr.ap-southeast-1.amazonaws.com/petpoha-web:latest

  # Configure NGINX reverse proxy
  cat <<EOL | sudo tee /etc/nginx/sites-available/petpoha
  server {
      listen 80;
      server_name petpoha.com www.petpoha.com;

      location / {
          proxy_pass http://localhost:3000;
          proxy_http_version 1.1;
          proxy_set_header Upgrade \$http_upgrade;
          proxy_set_header Connection 'upgrade';
          proxy_set_header Host \$host;
          proxy_cache_bypass \$http_upgrade;
      }
  }
  EOL

  # Enable the NGINX site and restart
  sudo ln -s /etc/nginx/sites-available/petpoha /etc/nginx/sites-enabled/
  sudo nginx -t
  sudo systemctl reload nginx
  EOF

  tags = {
    Name = "${var.app_name}-instance"
  }
}
