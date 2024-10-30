provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Create an AWS key pair for SSH access using the public key from login.tf
resource "aws_key_pair" "k3s_key_pair" {
  key_name   = "k3s-key-pair"
  public_key = tls_private_key.k3s_key.public_key_openssh
}

resource "aws_key_pair" "web_key" {
  key_name   = "web_key"
  public_key = file("~/.ssh/web_key.pub")  # Ensure this path is correct
}


# Create a VPC for the k3s environment
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = { Name = "k3s-vpc" }
}

# Define a public subnet for the k3s instances
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  tags = { Name = "k3s-public-subnet" }
}

# Define a private subnet for the k3s cluster
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr
  tags = { Name = "k3s-private-subnet" }
}

# Configure an internet gateway for public internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "k3s-igw" }
}

# Public route table to direct traffic to the internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "k3s-public-rt" }
}

# Define a route table for the private subnet to use a NAT gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Name = "k3s-private-rt" }
}

# Associate route tables with respective subnets
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create an Elastic IP for the NAT gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway to enable internet access for the private subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = { Name = "k3s-nat-gw" }
}

# Define security group for k3s cluster
resource "aws_security_group" "k3s_cluster" {
  name        = "k3s-cluster-sg"
  description = "Security group for k3s cluster"
  vpc_id      = aws_vpc.main.id
  
  # Ingress rules for k3s cluster communication
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]  # Allow communication within the VPC
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]  # Allow all traffic within the VPC
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
}

  tags = { Name = "k3s-cluster-sg" }
}

# Security group for the Nginx load balancer
resource "aws_security_group" "nginx" {
  name        = "nginx-sg"
  description = "Security group for NGINX load balancer and SSH"
  vpc_id      = aws_vpc.main.id
  
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
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
}
  
  tags = { Name = "nginx-sg" }
}

# Generate a random token for k3s nodes to join the cluster
resource "random_password" "k3s_token" {
  length  = 16
  special = false
}

# Launch the k3s master node in the public subnet
resource "aws_instance" "k3s_master" {
  ami                    = "ami-047126e50991d067b"  # Replace with a valid AMI for your region
  instance_type         = "t2.micro"
  subnet_id             = aws_subnet.public.id  # Change to public subnet
  vpc_security_group_ids = [aws_security_group.k3s_cluster.id]

key_name = aws_key_pair.web_key.key_name  # Use the correct key pair for SSH access

  # Add tags for the master instance
  tags = {
    Name        = "k3s-master"
    Environment = "Development"  # You can change this as needed
  }

  # Enable public IP assignment
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Update packages and install curl
              sudo apt-get update -y
              sudo apt-get install -y curl

              # Install k3s
              curl -sfL https://get.k3s.io | K3S_TOKEN="${random_password.k3s_token.result}" sh -

              # Output the K3S_TOKEN to a file
              echo "\$(cat /var/lib/rancher/k3s/server/node-token)" > /var/lib/rancher/k3s/server/node-token
              EOF
}

# Launch the worker nodes in the public subnet
resource "aws_instance" "k3s_worker" {
  count                   = 2
  ami                     = "ami-047126e50991d067b"  # Replace with a valid AMI for your region
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id  # Change to public subnet
  vpc_security_group_ids  = [aws_security_group.k3s_cluster.id]

  key_name = aws_key_pair.web_key.key_name  # Use the correct key pair for SSH access

  # Add tags for the worker instances
  tags = {
    Name        = "k3s-worker-${count.index + 1}"  # Naming workers as k3s-worker-1, k3s-worker-2, etc.
    Environment = "Development"  # You can change this as needed
  }

  user_data = templatefile("${path.module}/worker_user_data.sh", {
    master_ip = aws_instance.k3s_master.private_ip
    region    = var.region
  })
}
