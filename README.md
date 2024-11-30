# PetPoha Infrastructure with Terraform

![Terraform](https://img.shields.io/badge/Terraform-Required-orange)
![AWS](https://img.shields.io/badge/AWS-Cloud-lightgrey)

This repository contains Terraform configuration files to provision infrastructure on AWS for the **PetPoha Food for Pets** project. The infrastructure includes a **Virtual Private Cloud (VPC)**, **subnets**, **security groups**, an **EC2 instance**, and an **SSH key pair** for secure access.

## 🚀 Overview

The Terraform scripts in this project create the following AWS resources:
- **VPC**: A custom Virtual Private Cloud with DNS support and hostnames enabled.
- **Subnets**:
  - **Public Subnet**: For resources that need to be publicly accessible.
  - **Private Subnet**: For resources that do not need to be publicly accessible.
- **Security Groups**: A security group allowing SSH (port 22), HTTP (port 80), and HTTPS (port 443) traffic.
- **EC2 Instance**: A compute instance running Amazon Linux, which installs Nginx upon initialization.
- **SSH Key Pair**: A key pair created using the Ed25519 algorithm for secure access to the EC2 instance.

## 🛠️ Prerequisites

Before running the Terraform scripts, ensure you have the following:

- **AWS Account**: An AWS account with appropriate permissions.
- **Terraform**: Install Terraform on your local machine. Follow the official [installation guide](https://learn.hashicorp.com/tutorials/terraform/install-cli).
- **AWS CLI**: Optionally, you can use the AWS CLI for configuration and verification. Install it from the [official documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

## 🚦 Setup Instructions

1. **Clone the Repository**:
   ```bash
   git clone <repository_url>
   cd <repository_directory>
