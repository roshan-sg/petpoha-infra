output "ec2_public_ip" {
  value       = aws_instance.app_instance.public_ip
  description = "The public IP address of the EC2 instance."
}

output "ec2_public_dns" {
  value       = aws_instance.app_instance.public_dns
  description = "The public DNS of the EC2 instance."
}

output "vpc_id" {
  value       = aws_vpc.app_vpc.id
  description = "The ID of the VPC."
}

output "public_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "The ID of the public subnet."
}

# output "private_subnet_id" {
#   value       = aws_subnet.private_subnet.id
#   description = "The ID of the private subnet."
# }
