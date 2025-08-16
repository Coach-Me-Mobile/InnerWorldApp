# InnerWorld Scripts Directory

Quick reference guide for all development and deployment scripts.

## 📱 **Asset Management Scripts**

### **🎯 Primary Script: `assets.sh` (Recommended)**

**One-stop-shop for all asset operations**

```bash
# Make executable (one-time setup)
chmod +x scripts/assets.sh

# Quick commands
./scripts/assets.sh upload ./my-assets/              # Upload to dev
./scripts/assets.sh download -e prod                 # Download from prod
./scripts/assets.sh list -e staging                  # Browse staging assets
./scripts/assets.sh sync dev staging                 # Sync environments
./scripts/assets.sh compare dev prod                 # Compare assets
./scripts/assets.sh info                             # Show system status

# Get help for any command
./scripts/assets.sh help upload
./scripts/assets.sh --help
```

**Available Commands:**
- `upload` - Upload assets to S3 bucket
- `download` - Download assets from S3 bucket  
- `list` - List/browse assets in S3 bucket
- `sync` - Sync assets between environments or local/remote
- `compare` - Compare assets between environments
- `info` - Show bucket and environment information

### **📤 Legacy Scripts (Still Available)**

#### **`upload-assets.sh`**
Full-featured upload script with CloudFront invalidation support.

```bash
chmod +x scripts/upload-assets.sh

# Basic usage
./scripts/upload-assets.sh ./my-assets/              # Upload to dev
./scripts/upload-assets.sh -e prod -c ./assets/     # Upload to prod + invalidate cache
./scripts/upload-assets.sh -d ./assets/             # Dry run preview
```

#### **`simple-upload.sh`**
Basic S3 sync without CloudFront complexity.

```bash
chmod +x scripts/simple-upload.sh

# Simple uploads
./scripts/simple-upload.sh ./assets/                # Upload to dev
./scripts/simple-upload.sh -e prod ./assets/        # Upload to prod
```

## 🔧 **Development Scripts**

### **Environment Management**

#### **`setup-dev-environment.sh`**
Set up local development environment with all dependencies.

```bash
./scripts/setup-dev-environment.sh
```

### **Validation Scripts**

#### **`validate-api-endpoints.sh`**
Validate API endpoints are responding correctly.

```bash
./scripts/validate-api-endpoints.sh
```

#### **`validate-crisis-resources.sh`**
Validate crisis intervention resources and endpoints.

```bash
./scripts/validate-crisis-resources.sh
```

#### **`validate-ios-project.sh`**
Validate iOS project configuration and dependencies.

```bash
./scripts/validate-ios-project.sh
```

#### **`check-hardcoded-strings.sh`**
Check for hardcoded strings that should be configurable.

```bash
./scripts/check-hardcoded-strings.sh
```

## 🧪 **Testing Scripts**

### **CI/CD Testing**

#### **`ci-test.sh`**
Run comprehensive CI/CD tests locally.

```bash
./scripts/ci-test.sh
```

#### **`test-ios-ci-locally.sh`**
Test iOS CI pipeline locally before pushing.

```bash
./scripts/test-ios-ci-locally.sh
```

**Note**: Additional backend testing scripts are available in `backend/scripts/`:
- `test-unit.sh` - Unit tests for Go components
- `test-integration.sh` - Integration tests
- `test-e2e-conversation.sh` - End-to-end conversation tests
- `test-health.sh` - Health check validation
- `test-sam-local.sh` - Local SAM testing

## 🏗️ **Setup & Prerequisites**

### **Required Tools**
- **AWS CLI** (v2+) - `brew install awscli`
- **Go** (1.21+) - `brew install go`
- **jq** - `brew install jq`
- **Docker** - For local testing
- **SAM CLI** - For Lambda testing

### **AWS Configuration**
```bash
# Configure AWS credentials
aws configure
# AWS Access Key ID: [YOUR_ACCESS_KEY]
# AWS Secret Access Key: [YOUR_SECRET_KEY]  
# Default region: us-east-1
# Default output format: json

# Test configuration
aws sts get-caller-identity
./scripts/assets.sh info
```

### **Permissions Required**
Scripts require AWS IAM permissions for:
- **S3**: GetObject, PutObject, DeleteObject, ListBucket
- **CloudFront**: CreateInvalidation (for production)
- **Lambda**: InvokeFunction (for testing)
- **DynamoDB**: Query, PutItem (for integration tests)

## 🚀 **Common Workflows**

### **🎨 Asset Development Workflow**

```bash
# 1. Upload new assets to dev for testing
./scripts/assets.sh upload ./new-designs/

# 2. Test in mobile app, then promote to staging
./scripts/assets.sh sync dev staging

# 3. After approval, deploy to production
./scripts/assets.sh upload -e prod -c ./final-assets/
```

### **🔄 Environment Sync Workflow**

```bash
# 1. Compare environments
./scripts/assets.sh compare dev staging

# 2. Sync differences
./scripts/assets.sh sync dev staging

# 3. Verify sync completed
./scripts/assets.sh compare dev staging --summary-only
```

### **🧪 Testing Workflow**

```bash
# 1. Run unit tests
./scripts/test-unit.sh

# 2. Build for deployment
./scripts/build-for-terraform.sh

# 3. Test locally
./scripts/test-sam-local.sh

# 4. Run integration tests
./scripts/test-integration.sh

# 5. End-to-end validation
./scripts/test-e2e-conversation.sh
```

### **🚀 Deployment Workflow**

```bash
# 1. Start development environment
./scripts/dev-start.sh

# 2. Build and test
./scripts/build-for-terraform.sh
./scripts/test-unit.sh

# 3. Upload assets
./scripts/assets.sh upload -e staging ./assets/

# 4. Deploy via Terraform (manual)
cd infrastructure/environments/staging
terraform apply

# 5. Validate deployment
./scripts/test-health.sh
```

## 🐛 **Troubleshooting**

### **Common Issues**

#### **Permission Denied**
```bash
# Make script executable
chmod +x scripts/script-name.sh

# Check AWS permissions
aws sts get-caller-identity
./scripts/assets.sh info
```

#### **AWS CLI Not Found**
```bash
# Install AWS CLI
brew install awscli

# Verify installation
aws --version
```

#### **Script Fails**
```bash
# Check prerequisites
./scripts/check-aws-tools.sh

# Run with verbose output
bash -x scripts/script-name.sh
```

#### **S3 Access Issues**
```bash
# Test S3 access
aws s3 ls s3://innerworld-dev-app-assets/

# Check bucket permissions
./scripts/assets.sh info
```

## 📚 **Documentation References**

- **Asset Management**: `docs/ASSET_MANAGEMENT_GUIDE.md`
- **AWS Console Setup**: `docs/AWS_CONSOLE_DEVELOPER_ACCESS.md`
- **CI/CD Troubleshooting**: `docs/CI_CD_TROUBLESHOOTING_GUIDE.md`
- **Local Testing**: `docs/LOCAL_CI_TESTING.md`

## 🔗 **Quick Reference**

| Task | Script | Example |
|------|--------|---------|
| Upload assets | `assets.sh upload` | `./scripts/assets.sh upload ./images/` |
| Download assets | `assets.sh download` | `./scripts/assets.sh download -e prod` |
| List assets | `assets.sh list` | `./scripts/assets.sh list -e staging -l` |
| Sync environments | `assets.sh sync` | `./scripts/assets.sh sync dev staging` |
| Test backend | `test-unit.sh` | `./scripts/test-unit.sh` |
| Build for deploy | `build-for-terraform.sh` | `./scripts/build-for-terraform.sh` |
| Check AWS setup | `check-aws-tools.sh` | `./scripts/check-aws-tools.sh` |
| Health check | `test-health.sh` | `./scripts/test-health.sh` |

---

**💡 Pro Tip**: Use `./scripts/assets.sh` for all asset operations - it's the most comprehensive and user-friendly option!

For detailed help on any script: `./scripts/script-name.sh --help`
