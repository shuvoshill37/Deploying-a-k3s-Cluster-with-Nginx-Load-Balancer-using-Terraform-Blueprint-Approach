# Deploying-a-k3s-Cluster-with-Nginx-Load-Balancer-using-Terraform-Blueprint-Approach
Deploying a k3s Cluster with Nginx Load Balancer using Terraform Blueprint Approach_ Poridhi Exam Lab-111

Overview

This guide outlines the deployment of a k3s Kubernetes cluster with an NGINX load balancer using Terraform for infrastructure setup. The configuration uses a master node and two worker nodes. Terraform provisions the instances, and Kubernetes manages the load balancer configuration through an Ingress Controller.

Prerequisites

    Terraform v1.5.2 or later installed on a Linux system
    k3s installed for Kubernetes lightweight deployment
    kubectl for managing the Kubernetes cluster
    NGINX Ingress Controller configured in Kubernetes

Directory Structure

![Screen Shot 2024-11-01 at 4 21 51 PM](https://github.com/user-attachments/assets/f0fa54e1-b972-4837-9628-3736a8d8e90c)


Step-by-Step Guide
1. Configure Terraform Files

    main.tf: Define AWS EC2 resources (Ubuntu instances) for k3s master and worker nodes.
    variables.tf: Add variables for configuration (e.g., region, instance_type).
    outputs.tf: Specify outputs, like public IPs of the master and worker nodes.

2. Provision Infrastructure with Terraform

Initialize Terraform, apply configurations, and confirm instance creation:
    terraform init
    terraform apply -auto-approve
    
3. Set Up k3s on EC2 Instances

SSH into the instances and install k3s:

    Designate one instance as the master node, and install k3s with the --server flag.
    Join other nodes as workers using the master node’s token.

4. Deploy NGINX Ingress Controller

    Apply the nginx-ingress.yaml configuration using kubectl to set up the NGINX load balancer.
    sudo kubectl apply -f nginx-ingress.yaml
    Check Ingress status:
    sudo kubectl get ingress

5. Access the Application

After deploying, you can access the application through the master node’s public IP configured in the Ingress.


Notes

    Security: Ensure security groups allow HTTP/HTTPS access.
    Monitoring: Check kubectl logs for NGINX Ingress troubleshooting.

    
