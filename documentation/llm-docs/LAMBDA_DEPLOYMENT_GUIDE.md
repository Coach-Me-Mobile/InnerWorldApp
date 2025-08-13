# Lambda Deployment Guide

## Quick Start

Your Go Lambda functions are now integrated into the Terraform infrastructure! Here's how to deploy them:

### 1. Build Lambda Functions

```bash
cd backend/
make build-lambda
```

This creates:
- `backend/bin/health-check.zip` 
- `backend/bin/conversation-handler.zip`

### 2. Deploy Infrastructure

```bash
cd infrastructure/environments/dev/
terraform init
terraform plan
terraform apply
```

### 3. Test Your Deployment

After deployment, Terraform will output your API endpoints:

```bash
terraform output api_endpoints
```

**Health Check (REST API):**
```bash
curl https://{api-id}.execute-api.us-east-1.amazonaws.com/dev/health
```

**WebSocket Connection:**
```javascript
const ws = new WebSocket('wss://{api-id}.execute-api.us-east-1.amazonaws.com/dev');
ws.onopen = () => {
  ws.send(JSON.stringify({
    action: 'conversation',
    message: 'Hello!',
    userId: 'test-user'
  }));
};
```

## What's Deployed

### Lambda Functions
- **conversation-handler**: Handles both REST and WebSocket requests
- **health-check**: Simple health monitoring endpoint
- Both use `provided.al2` runtime with `bootstrap` handler

### API Gateways  
- **REST API**: `/health` GET endpoint
- **WebSocket API**: Real-time conversation handling with `$connect`, `$disconnect`, `$default` routes

### Infrastructure Integration
- ✅ **VPC**: Lambda functions deploy to existing private subnets
- ✅ **Security**: Uses existing Lambda security group with proper egress rules  
- ✅ **IAM**: Lambda execution role with Secrets Manager access
- ✅ **Secrets**: Access to OpenAI, OpenRouter, Neptune credentials
- ✅ **Monitoring**: CloudWatch log groups with configurable retention

## Next Steps

1. **Test the deployment** in dev environment
2. **Update conversation handler** to detect WebSocket vs REST events  
3. **Add DynamoDB tables** for conversation storage if needed
4. **Deploy to staging/prod** environments

## Lambda Function Updates

Your conversation handler should detect event type:

```go
func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
    // Check if it's a WebSocket event
    if request.RequestContext.RouteKey != "" {
        return handleWebSocketMessage(ctx, request)
    }
    // Otherwise handle as REST API
    return handleRESTRequest(ctx, request)
}
```

## Troubleshooting

**Build Issues:**
```bash
cd backend && make clean && make build-lambda
```

**Terraform Issues:**  
```bash
terraform plan  # Check what will be created
terraform destroy  # Clean slate if needed
```

**Function Logs:**
```bash
aws logs tail /aws/lambda/innerworld-dev-conversation-handler --follow
aws logs tail /aws/lambda/innerworld-dev-health-check --follow
```

Ready to deploy! 🚀
