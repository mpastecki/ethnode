# Terraform ETH Node

This repository contains Terraform code for deploying infrastructure.

## Prerequisites

- Install [Terraform](https://www.terraform.io/downloads.html)
- Set up your cloud provider credentials

## Deployment

1. Clone this repository
2. Navigate to the repository directory
3. Enter the terraform directory
4. Initialize Terraform by running `terraform init`
5. Review the changes that will be made by running `terraform plan`
6. Apply the changes by running `terraform apply`

## Eth Node Setup

Once the Terraform code finishes, you can run the job with this commad:

```
ssh -i (terraform output -raw ssh_private_key) ubuntu@(terraform output -raw first_instance_public_ip) "nomad job run -" < ../nomad_jobs/ethnode.nomad
```

You can check the status and access the logs by opening the Nomad UI. One way to do it is to redirect the remote port 4646 to localhost:
```
ssh -L 4646:localhost:4646 -i (terraform output -raw ssh_private_key) ubuntu@(terraform output -raw first_instance_public_ip) 
```
and opening http://localhost:4646

## 

There are several items missing from this setup that should be added if this was a real production use case. EIP attachement is one of them.
SSH Access over public Network is also something that may not be the best idea.