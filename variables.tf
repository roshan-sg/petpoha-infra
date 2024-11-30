variable "app_name" {
  description = "Name of the application (e.g., petpoha)"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "796973505325"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0c1a7f89451184c8b"  # Change this to match your region's AMI
}

variable "key_name" {
  description = "SSH key name for EC2 instance"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr_block" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}
