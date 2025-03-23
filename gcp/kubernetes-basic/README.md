# GCP Kubernetes Cluster Terraform Configuration

This Terraform project creates a Kubernetes (GKE) cluster in Google Cloud Platform with environment-specific configurations.

## Project Structure

```
.
├── env
│   ├── dev
│   ├── staging
│   └── prod
├── modules
│   ├── gke
│   ├── vpc
│   └── node_pool
└── README.md
```

## Environments

The `env` directory contains environment-specific configurations:

- `dev`: Development environment
- `staging`: Staging/QA environment
- `prod`: Production environment

Each environment folder contains:

- `main.tf`: Main configuration that references modules
- `variables.tf`: Variable definitions
- `terraform.tfvars`: Environment-specific variable values

## Modules

The `modules` directory contains reusable Terraform modules:

- `gke`: Google Kubernetes Engine cluster configuration
- `vpc`: Network and subnetwork resources
- `node_pool`: Node pool configuration for the GKE cluster

## Usage

1. Navigate to the desired environment directory:

```bash
cd env/dev
```

2. Initialize Terraform:

```bash
terraform init
```

3. Review the planned changes:

```bash
terraform plan
```

4. Apply the configuration:

```bash
terraform apply
```

5. To destroy the resources:

```bash
terraform destroy
```

## Customizing Configurations

Edit the `terraform.tfvars` file in the respective environment directory to customize:

- Project ID
- Cluster name
- Region (default: europe-west2)
- Node count
- Machine type
- Disk size
- Network configuration

## Prerequisites

- Google Cloud SDK installed and configured
- Terraform v1.0.0+ installed
- Appropriate GCP permissions to create resources
- GCP project with the required APIs enabled:
  - Kubernetes Engine API
  - Compute Engine API
  - IAM API
