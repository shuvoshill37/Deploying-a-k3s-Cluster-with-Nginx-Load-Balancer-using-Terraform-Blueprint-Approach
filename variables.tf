variable "aws_region" { 
    default = "ap-southeast-1" 
    }
variable "vpc_cidr" { 
    default = "10.0.0.0/16" 
    }
variable "public_subnet_cidr" { 
    default = "10.0.1.0/24" 
    }
variable "private_subnet_cidr" { 
    default = "10.0.2.0/24" 
    }
variable "instance_type" { 
    default = "t3.small" 
    }
variable "ubuntu_ami" { 
    default = "ami-047126e50991d067b" 
    }
variable "key_name" { 
    default = "my-keypair" 
    }

variable "aws_access_key" {
  description = "Initial AWS Access Key"
  type        = string
}

variable "aws_secret_key" {
  description = "Initial AWS Secret Access Key"
  type        = string
}

variable "region" {
  default = "ap-southeast-1"
}



