# Generate a new RSA key pair for SSH access to the k3s cluster
resource "tls_private_key" "k3s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


#################


# Output the SSH public key to be used in main.tf
output "k3s_public_key_openssh" {
  value = tls_private_key.k3s_key.public_key_openssh
}

# Store the private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.k3s_key.private_key_pem
  filename        = "${path.module}/k3s-key-pair.pem"
  file_permission = "0600"
}

# Output the private key content for reference if needed
output "k3s_private_key_pem" {
  value     = tls_private_key.k3s_key.private_key_pem
  sensitive = true
}


