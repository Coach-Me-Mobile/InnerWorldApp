# InnerWorldApp Infrastructure

This directory contains the production-ready Terraform Infrastructure as Code (IaC) for the InnerWorldApp project. The infrastructure is designed to support a secure, scalable iOS VR application with real-time teen chat, AI personas, and GraphRAG emotional intelligence.

## 📋 Overview

The infrastructure provides a complete serverless backend for teen VR conversations:

- **🌐 VPC & Networking**: Multi-AZ VPC with public/private/database subnets and security groups
- **🔒 AWS Cognito**: Teen authentication with Apple Sign-In and email/password support
- **🗄️ Neptune GraphRAG**: Graph database for storing emotional context and conversation patterns
- **🚀 DynamoDB**: Real-time conversation storage with TTL cleanup (24h/30min/1h)
- **⚡ WebSocket API**: JWT-secured real-time chat with Lambda handlers
- **🔐 Secrets Manager**: Secure storage for API keys and credentials
- **📊 CloudWatch**: Comprehensive monitoring, logging, and alerting
- **🎯 Cost-Optimized**: Production-ready architecture starting at $400/month for 100 teens

## 🏗️ Architecture

```
┌─ Production Environment ─┐    ┌─ Core Modules ─┐
│                          │    │                │
│ └── prod/               │ => │ networking     │
│     ├── main.tf         │    │ cognito        │
│     └── terraform.tfvars│    │ neptune        │
│                          │    │ dynamodb       │
└──────────────────────────┘    │ lambda         │
                                │ secrets        │
┌─ Shared Backend ─┐             └────────────────┘
│                  │                     ↑
│ backend.tf       │ ────────────────────┘
│                  │
└──────────────────┘
```

## 🎯 Teen VR Chat Flow

**Authentication & Connection:**
```
iOS VR App → Cognito (Apple Sign-In) → JWT Token → WebSocket API → Connect Handler → DynamoDB Connection Tracking
```

**Real-Time Conversation:**
```
Teen Message → WebSocket → Lambda → DynamoDB (live) + Neptune (context) → OpenRouter (Claude) → Response
```

**Session Processing:**
```
Session End → Extract Themes → Update Neptune Graph → Cache Context → TTL Cleanup
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform >= 1.5** installed
3. **Apple Developer Account** (for Apple Sign-In)
4. **OpenRouter API Key** (for Claude conversations)

### Step 1: Create Backend Infrastructure

First, create the S3 bucket and DynamoDB table for Terraform state:

```bash
cd infrastructure/shared
terraform init
terraform plan
terraform apply
```

This creates:
- S3 bucket for Terraform state: `innerworld-prod-terraform-state`
- DynamoDB table for state locking: `innerworld-prod-terraform-locks`
- IAM policies for backend access

### Step 2: Deploy Production Environment

```bash
cd infrastructure/environments/prod

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Apple and OpenRouter credentials

# Initialize with backend
terraform init

# Plan and apply
terraform plan
terraform apply
```

### Step 3: Configure Secrets

After deployment, update the secrets in AWS Secrets Manager:

```bash
# Update OpenRouter API key
aws secretsmanager update-secret \
  --secret-id "innerworld-prod/openai/api-key" \
  --secret-string '{"api_key":"sk-or-v1-your-key","provider":"openrouter","base_url":"https://openrouter.ai/api/v1","model_primary":"anthropic/claude-3.5-sonnet","model_fallback":"openai/gpt-4"}'

# Update Apple Sign-In credentials
aws secretsmanager update-secret \
  --secret-id "innerworld-prod/apple/signin-key" \
  --secret-string '{"team_id":"YOUR_TEAM_ID","key_id":"YOUR_KEY_ID","private_key":"YOUR_PRIVATE_KEY","client_id":"com.gauntletai.innerworld"}'
```

### Step 4: Verify Deployment

```bash
# Check all outputs
terraform output

# Test API endpoints
curl $(terraform output -raw api_endpoints | jq -r '.health_check_url')

# Verify Neptune cluster is running
aws neptune describe-db-clusters --db-cluster-identifier innerworld-prod-neptune-cluster
```

## 📁 Directory Structure

```
infrastructure/
├── README.md                          # This file
├── main.tf                           # Root module configuration
├── variables.tf                      # Root module variables
├── outputs.tf                       # Root module outputs
│
├── environments/                     # Production environment
│   └── prod/
│       ├── main.tf                  # Production configuration
│       └── terraform.tfvars.example # Example variables
│
├── modules/                         # Reusable Terraform modules
│   ├── networking/                  # VPC, subnets, security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cognito/                     # Authentication with Apple Sign-In
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── cognito_triggers/        # Lambda trigger functions
│   ├── neptune/                     # GraphRAG cluster
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── dynamodb/                    # Real-time conversation storage
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── lambda/                      # WebSocket and conversation handlers
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── secrets/                     # AWS Secrets Manager
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── shared/                         # Terraform state backend
    └── backend.tf                  # S3 + DynamoDB for state
```

## 💾 Database Architecture

### 🗄️ Neptune GraphRAG Cluster

**Purpose**: Stores emotional intelligence and conversation patterns
- **Primary Instance**: `db.r5.large` (2 vCPUs, 16 GiB RAM)
- **Reader Instance**: `db.r5.large` (read-only replica)
- **Schema**: Events, Feelings, Values, Goals, Habits, Relationships
- **Edges**: temporal, causal, about, supports, conflicts, felt_during
- **Backup**: 90-day retention with point-in-time recovery

### 🚀 DynamoDB Tables

**LiveConversations** (Real-time message storage):
- **Purpose**: Store messages during 20-minute VR sessions
- **Schema**: `conversation_id` + `message_sequence`
- **GSIs**: SessionIndex, UserIndex
- **TTL**: 24 hours (auto-cleanup after Neptune processing)

**WebSocketConnections** (Connection tracking):
- **Purpose**: Track active WebSocket connections for message delivery
- **Schema**: `connection_id` with user/session metadata
- **GSIs**: UserConnectionsIndex, SessionConnectionsIndex
- **TTL**: 30 minutes (auto-cleanup of stale connections)

**SessionContext** (Context cache):
- **Purpose**: Cache Neptune context for fast conversation responses
- **Schema**: `user_id` + `session_id`
- **TTL**: 1 hour (refreshed each session)

## 🔐 Security Features

### Network Security
- **VPC**: Isolated 10.0.0.0/16 network with 3 AZ redundancy
- **Security Groups**: Neptune (port 8182), Lambda (HTTPS + Neptune)
- **NACLs**: Additional network-level protection
- **VPC Endpoints**: S3, DynamoDB, Secrets Manager (no internet routing)

### Authentication & Authorization
- **Cognito User Pool**: Teen authentication with email verification
- **Apple Sign-In**: Seamless iOS integration for teens 13+
- **JWT Authorizer**: WebSocket connections secured with Cognito tokens
- **IAM Roles**: Least-privilege access for all components

### Data Protection
- **Encryption**: All data encrypted at rest (KMS) and in transit (TLS)
- **Secrets Manager**: Rotatable API keys and credentials
- **Neptune IAM Auth**: No database passwords, SigV4 authentication
- **Audit Logging**: Comprehensive CloudWatch audit trails

## 📊 Monitoring & Observability

### CloudWatch Alarms
- **Neptune**: CPU > 80%, FreeableMemory < 256MB, Connection count
- **DynamoDB**: ThrottledRequests, SystemErrors for all tables
- **Lambda**: Errors, Throttles, Duration p95 for all functions
- **WebSocket API**: 4XX/5XX error rates, connection anomalies

### Access Logging
- **WebSocket API**: Request ID, IP, route, status, errors
- **Lambda Functions**: Execution logs with request tracing
- **Neptune**: Audit logs for all graph operations

### Cost Monitoring
- **Comprehensive Tagging**: Project, Environment, Purpose tags
- **Resource Optimization**: TTL cleanup, on-demand billing
- **Scaling Metrics**: Per-teen cost tracking and optimization

## 💰 Cost Analysis & Scalability

### Production Costs by User Tier

| Users | Monthly Cost | Cost/Teen | Key Scaling Factor |
|-------|-------------|-----------|-------------------|
| 100   | $400        | $4.00     | Fixed Neptune cluster |
| 1,000 | $710        | $0.71     | DynamoDB & Lambda scale |
| 10,000| $3,125      | $0.31     | Neptune instance upgrade |
| 100,000| $18,500     | $0.19     | Multi-region deployment |

### Scalability Limits
- **Neptune**: 1,000 concurrent queries (db.r5.large), scales to 10K+ with clustering
- **DynamoDB**: Unlimited with on-demand billing (20M+ requests/second)
- **Lambda**: 1,000 concurrent executions (configurable to 10K+)
- **WebSocket API**: 10,000 concurrent connections (increasable)

### Optimization Strategies
- **0-1K users**: Single Neptune cluster, on-demand DynamoDB
- **1K-10K users**: Add read replicas, provisioned Lambda concurrency
- **10K+ users**: Multi-region clusters, DynamoDB Global Tables

## 🛠️ Common Operations

### Deploying Updates

```bash
# Navigate to production
cd infrastructure/environments/prod

# Plan changes
terraform plan

# Apply changes
terraform apply

# Target specific modules
terraform apply -target=module.lambda
```

### Managing Secrets

```bash
# List all secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `innerworld-prod`)]'

# Update OpenRouter model configuration
aws secretsmanager update-secret \
  --secret-id "innerworld-prod/openai/api-key" \
  --secret-string '{"api_key":"your-key","model_primary":"anthropic/claude-3.5-sonnet","model_fallback":"openai/gpt-4o"}'
```

### Monitoring Health

```bash
# Check Neptune cluster status
aws neptune describe-db-clusters --db-cluster-identifier innerworld-prod-neptune-cluster

# Monitor DynamoDB tables
aws dynamodb describe-table --table-name innerworld-prod-live-conversations

# View Lambda function logs
aws logs tail /aws/lambda/innerworld-prod-conversation-handler --follow
```

### Scaling Operations

```bash
# Upgrade Neptune instance class
terraform apply -var="neptune_instance_class=db.r5.xlarge"

# Add Neptune read replica
terraform apply -var="neptune_instance_count=3"

# Enable DynamoDB streams for processing
terraform apply -var="enable_dynamodb_streams=true"
```

## 🐛 Troubleshooting

### Common Issues

**WebSocket Connection Failures**:
```bash
# Check JWT authorizer configuration
aws apigatewayv2 get-authorizer --api-id <websocket-api-id> --authorizer-id <authorizer-id>

# Verify Cognito token
aws cognito-idp get-user --access-token <token>
```

**Neptune Connection Issues**:
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids <neptune-sg-id>

# Test from Lambda
aws lambda invoke --function-name innerworld-prod-conversation-handler test-output.json
```

**DynamoDB Throttling**:
```bash
# Check table metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ThrottledRequests \
  --dimensions Name=TableName,Value=innerworld-prod-live-conversations \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

## 🎯 Environment Variables for Go Backend

Your Lambda functions will have access to these environment variables:

```bash
# Database connections
NEPTUNE_ENDPOINT=innerworld-prod-neptune-cluster.cluster-xyz.neptune.amazonaws.com
NEPTUNE_READER_ENDPOINT=innerworld-prod-neptune-cluster.cluster-ro-xyz.neptune.amazonaws.com
NEPTUNE_PORT=8182
NEPTUNE_IAM_AUTH=true

# DynamoDB tables
LIVE_CONVERSATIONS_TABLE=innerworld-prod-live-conversations
WEBSOCKET_CONNECTIONS_TABLE=innerworld-prod-websocket-connections
SESSION_CONTEXT_TABLE=innerworld-prod-session-context

# Authentication
COGNITO_USER_POOL_ID=us-east-1_xxxxxxxxx
COGNITO_USER_POOL_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxx

# Configuration
ENVIRONMENT=prod
AWS_REGION=us-east-1
DEBUG=false
```

## 📚 Additional Resources

- [AWS Neptune Developer Guide](https://docs.aws.amazon.com/neptune/latest/userguide/)
- [DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/latest/developerguide/)
- [WebSocket API Gateway Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/websocket-api.html)
- [Cognito Developer Guide](https://docs.aws.amazon.com/cognito/latest/developerguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🤝 Contributing

1. **Infrastructure Changes**: Always test in a separate AWS account first
2. **Security First**: Follow least-privilege IAM principles
3. **Cost Awareness**: Monitor and optimize resource usage
4. **Documentation**: Update this README for any architectural changes
5. **Monitoring**: Add CloudWatch alarms for new components

## 🆘 Support

For infrastructure issues:
1. Check CloudWatch logs: `/aws/lambda/innerworld-prod-*`
2. Review Neptune audit logs: `/aws/neptune/innerworld-prod/audit`
3. Monitor DynamoDB metrics in CloudWatch console
4. Contact the GauntletAI infrastructure team

---

**🎯 This infrastructure is production-ready for teen VR conversations with emotional intelligence, real-time chat, and scalable cost structure. Perfect for launching your InnerWorld MVP!**