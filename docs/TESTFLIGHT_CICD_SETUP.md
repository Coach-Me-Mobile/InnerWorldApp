# InnerWorld iOS TestFlight - Simple Deployment Guide

**Quick overview of our streamlined TestFlight deployment approach.**

> 📋 **For complete deployment instructions, see**: [`docs/MANUAL_DEPLOYMENT_GUIDE.md`](./MANUAL_DEPLOYMENT_GUIDE.md)

## Overview

InnerWorld uses a **simple, cost-optimized deployment** approach focused on TestFlight delivery:

### ✅ **Cost-Optimized Infrastructure (~$180/month):**
- **Multi-AZ VPC**: High availability with NAT gateways (as requested)
- **AWS Cognito**: Apple Sign-In and email authentication 
- **Lambda Functions**: Go-based WebSocket API handlers for real-time chat
- **DynamoDB**: Real-time conversation storage with TTL
- **S3 Buckets**: App assets and TestFlight build storage
- **GitHub Actions**: Simple iOS CI/CD pipeline
- **Secrets Management**: Apple Developer and App Store Connect credentials

### ❌ **Disabled for Cost Savings:**
- **Neptune GraphRAG**: Expensive ($200+/month) - can be enabled later
- **VPC Flow Logs**: Reduced monitoring for cost savings
- **Extensive CloudWatch**: Minimal logging (1-day retention)

## Quick Start

### 1. Prerequisites
- AWS CLI with admin permissions
- Terraform >= 1.5
- Apple Developer Account
- GitHub repository with admin access

### 2. Deploy Infrastructure
```bash
# Follow the complete manual guide
open docs/MANUAL_DEPLOYMENT_GUIDE.md
```

### 3. Configure GitHub Actions
```bash
# Set up repository secrets manually
# See MANUAL_DEPLOYMENT_GUIDE.md for complete instructions
```

### 4. Test Deployment
```bash
# Push to main branch to trigger pipeline
git add .
git commit -m "test: trigger TestFlight deployment"
git push origin main
```

## Architecture Benefits

Our simple deployment approach provides:

### 🎯 **Focused on TestFlight**
- Minimal infrastructure for core functionality
- Cost-optimized for early-stage development
- Easy to understand and maintain

### 💰 **Cost-Effective**
- ~$180/month vs $400+ for full production
- Multi-AZ reliability maintained
- No unnecessary services running

### 🔧 **Manual Control**
- Complete visibility into every deployment step
- No black-box automation
- Easy troubleshooting and customization

### 🚀 **Production-Ready Foundation**
- Infrastructure scales to full production
- Add Neptune GraphRAG when needed
- Enable monitoring/logging as required

## Next Steps

1. **Deploy infrastructure** following the manual guide
2. **Configure GitHub Actions** with repository secrets
3. **Test iOS pipeline** with a commit push
4. **Monitor costs** in AWS billing dashboard
5. **Scale up** by enabling Neptune and enhanced monitoring when ready

## Migration Path

When ready for full production:

```bash
# Enable Neptune GraphRAG
# In terraform.tfvars:
# enable_neptune = true

# Enable enhanced monitoring  
# enable_vpc_flow_logs = true
# log_retention_days = 30

# Re-deploy with production settings
terraform apply -var-file=terraform.tfvars
```

---

**🎊 Ready for TestFlight deployment with minimal complexity and cost!**


