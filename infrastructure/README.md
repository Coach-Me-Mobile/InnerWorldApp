# InnerWorldApp Infrastructure

This directory contains the Terraform Infrastructure as Code (IaC) for the InnerWorldApp project. The infrastructure is designed to support a secure, scalable iOS application with AI personas and GraphRAG capabilities.

## 📋 Overview

The infrastructure includes:

- **VPC & Networking**: Multi-AZ VPC with public/private subnets, NAT gateways, and security groups
- **AWS Cognito**: User authentication with Apple Sign-In and email/password support
- **Secrets Manager**: Secure storage for API keys and credentials
- **CodePipeline**: CI/CD pipeline for automated testing and deployment
- **CloudWatch**: Monitoring, logging, and alerting
- **S3 & DynamoDB**: Terraform state management and application data

## 🏗️ Architecture

```
┌─ Environments ─┐    ┌─ Modules ─┐
│                 │    │           │
│ ├── dev/        │ => │ networking │
│ ├── staging/    │    │ cognito    │
│ └── prod/       │    │ secrets    │
│                 │    │ codepipeline│
└─────────────────┘    └───────────┘
                           ↑
┌─ Shared ─┐               │
│          │               │
│ backend/ │ ──────────────┘
│          │
└──────────┘
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform >= 1.6** installed
3. **GitHub repository** set up for the project
4. **AWS Account** with billing enabled

### Step 1: Create Backend Infrastructure

First, create the S3 buckets and DynamoDB tables for Terraform state:

```bash
cd infrastructure/shared
terraform init
terraform plan
terraform apply
```

This creates:
- S3 buckets for Terraform state (one per environment)
- DynamoDB tables for state locking
- IAM policies for backend access

### Step 2: Set Up GitHub Connection (Optional)

For CodePipeline integration:

1. Go to AWS Console → Developer Tools → Settings → Connections
2. Create a new connection to GitHub
3. Authorize the connection and note the ARN

### Step 3: Deploy Development Environment

```bash
cd infrastructure/environments/dev

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GitHub connection ARN (if using CodePipeline)

# Initialize with backend
terraform init

# Plan and apply
terraform plan
terraform apply
```

### Step 4: Configure Secrets

After deployment, you'll need to update the secrets in AWS Secrets Manager:

```bash
# List the created secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `innerworld-dev`)]'

# Update each secret with actual values
aws secretsmanager update-secret \
  --secret-id "innerworld-dev/openai/api-key" \
  --secret-string '{"api_key":"your-actual-openai-key","provider":"openrouter"}'

aws secretsmanager update-secret \
  --secret-id "innerworld-dev/neo4j/credentials" \
  --secret-string '{"uri":"your-neo4j-uri","username":"neo4j","password":"your-password"}'

# For Apple Sign-In (production environments)
aws secretsmanager update-secret \
  --secret-id "innerworld-dev/apple/signin-key" \
  --secret-string '{"team_id":"YOUR_TEAM_ID","key_id":"YOUR_KEY_ID","private_key":"YOUR_PRIVATE_KEY","client_id":"YOUR_CLIENT_ID"}'
```

## 📁 Directory Structure

```
infrastructure/
├── README.md                          # This file
├── main.tf                           # Root module configuration
├── variables.tf                      # Root module variables
├── outputs.tf                       # Root module outputs
│
├── environments/                     # Environment-specific configurations
│   ├── dev/
│   │   ├── main.tf                  # Development environment
│   │   └── terraform.tfvars.example # Example variables
│   ├── staging/
│   │   ├── main.tf                  # Staging environment
│   │   └── terraform.tfvars.example # Example variables
│   └── prod/
│       ├── main.tf                  # Production environment
│       └── terraform.tfvars.example # Example variables
│
├── modules/                         # Reusable Terraform modules
│   ├── networking/                  # VPC, subnets, security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cognito/                     # Authentication and authorization
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── cognito_triggers/        # Lambda trigger functions
│   ├── secrets/                     # AWS Secrets Manager
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── rotate_secrets.py        # Secret rotation script
│   └── codepipeline/               # CI/CD pipeline
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── shared/                         # Shared infrastructure
    └── backend.tf                  # Terraform state backend
```

## 🔧 Environment Configurations

### Development
- **Purpose**: Local development and testing
- **Cost Optimized**: Single NAT gateway, minimal logging
- **Features**: Relaxed security policies, no Apple Sign-In
- **Monitoring**: Basic CloudWatch logs

### Staging
- **Purpose**: Pre-production testing
- **Configuration**: Production-like but cost-conscious
- **Features**: Full authentication, CI/CD pipeline
- **Monitoring**: Enhanced logging and monitoring

### Production
- **Purpose**: Live application
- **Configuration**: High availability, security hardened
- **Features**: All features enabled, comprehensive monitoring
- **Monitoring**: Full observability stack with alerts

## 🔐 Security Features

### Network Security
- **VPC**: Isolated network environment
- **Security Groups**: Least-privilege access rules
- **NACLs**: Additional network-level security
- **VPC Endpoints**: Secure AWS service access

### Identity & Access
- **Cognito**: Managed authentication service
- **IAM Roles**: Principle of least privilege
- **MFA**: Multi-factor authentication support
- **Apple Sign-In**: Social authentication

### Data Protection
- **Secrets Manager**: Encrypted credential storage
- **Encryption**: Data encrypted at rest and in transit
- **Backup**: Automated backup strategies
- **Audit Logging**: Comprehensive audit trails

## 📊 Monitoring & Observability

### CloudWatch Integration
- **Logs**: Centralized log aggregation
- **Metrics**: Custom and AWS service metrics
- **Alarms**: Automated alerting on thresholds
- **Dashboards**: Real-time system visibility

### Cost Management
- **Tagging**: Comprehensive resource tagging
- **Budgets**: Environment-specific cost controls
- **Optimization**: Right-sizing and scheduling

## 🛠️ Common Operations

### Updating Infrastructure

```bash
# Navigate to environment
cd infrastructure/environments/dev

# Plan changes
terraform plan

# Apply changes
terraform apply

# Target specific resources
terraform apply -target=module.cognito
```

### Destroying Infrastructure

```bash
# Destroy environment (CAUTION: This will delete everything!)
terraform destroy

# Destroy specific modules
terraform destroy -target=module.codepipeline
```

### Viewing State

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show module.networking.aws_vpc.main

# View outputs
terraform output
```

## 🔄 CI/CD Pipeline

The CodePipeline includes:

1. **Source**: GitHub repository monitoring
2. **Security Scan**: SAST, dependency, and secret scanning
3. **Infrastructure Validation**: Terraform plan and validate
4. **iOS Build & Test**: Xcode build and unit tests
5. **Manual Approval**: (Production only)

### Pipeline Configuration

```yaml
# Example buildspec for iOS
version: 0.2
phases:
  install:
    runtime-versions:
      ios: 15.1
  pre_build:
    commands:
      - xcodebuild -version
      - pod install
  build:
    commands:
      - xcodebuild test -workspace InnerWorldApp.xcworkspace -scheme InnerWorldApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
  post_build:
    commands:
      - echo "Build completed"
```

## 🐛 Troubleshooting

### Common Issues

#### Backend Initialization Fails
```bash
# Ensure backend bucket exists
aws s3 ls s3://innerworld-dev-terraform-state

# Re-initialize if needed
terraform init -reconfigure
```

#### GitHub Connection Issues
```bash
# Verify connection status
aws codestar-connections get-connection --connection-arn your-connection-arn

# Re-authorize if needed in AWS Console
```

#### Permission Errors
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify IAM permissions for Terraform resources
```

### Debug Mode

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform plan

# Enable AWS CLI debug
export AWS_CLI_DEBUG=1
aws s3 ls
```

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Cognito Developer Guide](https://docs.aws.amazon.com/cognito/latest/developerguide/)
- [AWS Secrets Manager User Guide](https://docs.aws.amazon.com/secretsmanager/latest/userguide/)
- [AWS CodePipeline User Guide](https://docs.aws.amazon.com/codepipeline/latest/userguide/)

## 🤝 Contributing

1. **Plan First**: Always run `terraform plan` before applying changes
2. **Environment Isolation**: Test in dev before promoting to staging/prod
3. **Documentation**: Update this README when adding new components
4. **Security**: Follow least-privilege principles for all IAM policies
5. **Cost Awareness**: Consider cost implications of infrastructure changes

## 🆘 Support

For infrastructure issues:
1. Check the troubleshooting section above
2. Review AWS CloudWatch logs for error details
3. Consult the Terraform AWS provider documentation
4. Contact the GauntletAI infrastructure team
