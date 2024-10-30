# Outputs for the AWS infrastructure

# Output the VPC ID
output "vpc_id" {
  value = aws_vpc.main.id
}

# Output the public subnet ID
output "public_subnet_id" {
  value = aws_subnet.public.id
}

# Output the private subnet ID
output "private_subnet_id" {
  value = aws_subnet.private.id
}

# Output for the k3s master node IP
output "k3s_master_ip" {
  value = aws_instance.k3s_master.private_ip
}

# Output for the k3s worker nodes IPs
output "k3s_worker_ips" {
  value = aws_instance.k3s_worker[*].private_ip
}

