# InnerWorld Asset Management Guide

## 🎯 **One-Stop-Shop Asset Management**

The unified `assets.sh` script provides complete asset management for your mobile app across all environments.

### **📦 Quick Start**

```bash
# Make script executable (one-time setup)
chmod +x scripts/assets.sh

# Upload assets to development
./scripts/assets.sh upload ./my-assets/

# Download all production assets
./scripts/assets.sh download -e prod

# List assets in staging
./scripts/assets.sh list -e staging

# Sync from dev to staging
./scripts/assets.sh sync dev staging

# Compare environments
./scripts/assets.sh compare dev prod

# Get system info
./scripts/assets.sh info
```

## 📋 **Available Commands**

### **🔼 Upload Assets**

Upload local assets to S3 bucket with intelligent content-type detection.

```bash
# Basic usage
./scripts/assets.sh upload <source_path>

# Options
-e, --env ENV        Environment (dev, staging, prod) [default: dev]
-t, --target PATH    Target S3 path prefix [default: assets/]
-c, --invalidate     Invalidate CloudFront cache (production only)
-d, --dry-run        Preview what would be uploaded
--delete             Delete extraneous files from destination

# Examples
./scripts/assets.sh upload ./images/                    # Upload to dev/assets/
./scripts/assets.sh upload -e prod -c ./icons/          # Upload to prod + invalidate cache
./scripts/assets.sh upload -t images/ ./new-logos/      # Upload to dev/images/
./scripts/assets.sh upload -d ./assets/                 # Preview upload (dry run)
```

### **🔽 Download Assets**

Download assets from S3 to local directory.

```bash
# Basic usage
./scripts/assets.sh download [remote_path] [local_path]

# Options
-e, --env ENV        Environment (dev, staging, prod) [default: dev]
-d, --dry-run        Preview what would be downloaded
--delete             Delete extraneous local files

# Examples
./scripts/assets.sh download                            # Download all dev assets
./scripts/assets.sh download -e prod                    # Download all prod assets
./scripts/assets.sh download images/ ./my-images/       # Download specific folder
./scripts/assets.sh download assets/logo.png ./         # Download specific file
```

### **📋 List/Browse Assets**

Browse and explore assets in S3 buckets.

```bash
# Basic usage
./scripts/assets.sh list [path]

# Options
-e, --env ENV        Environment (dev, staging, prod) [default: dev]
-l, --long           Show detailed information (size, date)
-r, --recursive      List all files recursively
--human-readable     Show file sizes in human readable format

# Examples
./scripts/assets.sh list                                # List root of dev bucket
./scripts/assets.sh list -e prod -l                     # Detailed list of prod
./scripts/assets.sh list -r images/                     # Recursively list images/
./scripts/assets.sh list --human-readable assets/       # Human readable sizes
```

### **🔄 Sync Assets**

Sync assets between environments or local/remote locations.

```bash
# Basic usage
./scripts/assets.sh sync <source> <destination>

# Options
-d, --dry-run        Preview what would be synced
--delete             Delete extraneous files from destination
-c, --invalidate     Invalidate CloudFront cache if destination is prod

# Examples
./scripts/assets.sh sync dev staging                    # Environment to environment
./scripts/assets.sh sync prod ./backup/                 # Remote to local backup
./scripts/assets.sh sync ./local-assets/ dev            # Local to remote upload
./scripts/assets.sh sync -d dev prod                     # Preview sync (dry run)
```

### **⚖️ Compare Assets**

Compare assets between different environments.

```bash
# Basic usage
./scripts/assets.sh compare <env1> <env2>

# Options
--summary-only       Show only summary statistics

# Examples
./scripts/assets.sh compare dev prod                    # Compare dev vs prod
./scripts/assets.sh compare --summary-only staging prod # Summary only
```

### **ℹ️ System Info**

Display bucket status, CloudFront configuration, and AWS authentication info.

```bash
./scripts/assets.sh info
```

## 🏗️ **Infrastructure Overview**

### **S3 Buckets**
- **Dev**: `innerworld-dev-app-assets` (Direct S3 access)
- **Staging**: `innerworld-staging-app-assets` (Direct S3 access)  
- **Production**: `innerworld-prod-app-assets` (CloudFront CDN)

### **Access Patterns**
- **Development/Staging**: Direct S3 URLs for fast iteration
- **Production**: CloudFront CDN for global performance and caching

### **CloudFront Caching**
- **Default TTL**: 1 hour (3600 seconds)
- **Assets TTL**: 1 day to 1 year (configurable)
- **Cache Invalidation**: Available for production updates

## 📱 **Mobile App Integration**

### **Asset URL Patterns**

```swift
// Development/Staging (Direct S3)
let devAssetURL = "https://innerworld-dev-app-assets.s3.us-east-1.amazonaws.com/assets/logo.png"

// Production (CloudFront CDN)
let prodAssetURL = "https://d1234567890.cloudfront.net/assets/logo.png"
```

### **Environment-Specific Loading**

```swift
func getAssetURL(path: String) -> String {
    switch Environment.current {
    case .development:
        return "https://innerworld-dev-app-assets.s3.us-east-1.amazonaws.com/\(path)"
    case .staging:
        return "https://innerworld-staging-app-assets.s3.us-east-1.amazonaws.com/\(path)"
    case .production:
        return "https://d1234567890.cloudfront.net/\(path)"
    }
}
```

## 🔐 **Security & Access**

### **Required Permissions**

The script requires AWS credentials with these permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject", 
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::innerworld-*-app-assets",
                "arn:aws:s3:::innerworld-*-app-assets/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation",
                "cloudfront:GetInvalidation",
                "cloudfront:ListInvalidations"
            ],
            "Resource": "*"
        }
    ]
}
```

### **AWS CLI Setup**

```bash
# Configure AWS credentials
aws configure
# AWS Access Key ID: [YOUR_ACCESS_KEY]
# AWS Secret Access Key: [YOUR_SECRET_KEY]
# Default region: us-east-1
# Default output format: json

# Test access
./scripts/assets.sh info
```

## 🚀 **Common Workflows**

### **🎨 Design Asset Updates**

```bash
# 1. Upload new designs to dev for testing
./scripts/assets.sh upload -t designs/ ./new-designs/

# 2. Test in development app, then sync to staging
./scripts/assets.sh sync dev staging

# 3. After approval, sync to production with cache invalidation
./scripts/assets.sh sync -c staging prod
```

### **📦 App Release Preparation**

```bash
# 1. Compare environments to ensure consistency
./scripts/assets.sh compare staging prod

# 2. Download production backup before changes
./scripts/assets.sh download -e prod ./backup-$(date +%Y%m%d)/

# 3. Upload release assets with immediate cache clear
./scripts/assets.sh upload -e prod -c ./v2.0-assets/

# 4. Verify upload completed
./scripts/assets.sh list -e prod -l | grep v2.0
```

### **🔍 Asset Debugging**

```bash
# 1. List all assets to find the problematic one
./scripts/assets.sh list -e prod -r | grep logo

# 2. Download specific asset for inspection
./scripts/assets.sh download -e prod assets/logo.png ./debug/

# 3. Compare with other environments
./scripts/assets.sh compare dev prod | grep logo

# 4. Re-upload fixed version
./scripts/assets.sh upload -e prod -c -t assets/ ./fixed-logo.png
```

### **🧹 Environment Cleanup**

```bash
# 1. Compare environments to find differences
./scripts/assets.sh compare --summary-only dev staging

# 2. Preview what sync would do
./scripts/assets.sh sync -d --delete dev staging

# 3. Clean sync (removes extra files)
./scripts/assets.sh sync --delete dev staging
```

## ⚡ **Performance Tips**

### **Upload Optimization**
- **Compress images** before upload (use tools like ImageOptim)
- **Use WebP format** for better compression
- **Batch uploads** rather than individual files
- **Use dry-run** to preview large operations

### **Download Optimization**
- **Specify paths** to download only needed assets
- **Use --delete flag** carefully to avoid data loss
- **Consider bandwidth** for large asset downloads

### **CloudFront Best Practices**
- **Use cache invalidation sparingly** (costs $0.005 per path)
- **Group related assets** in same upload for batch invalidation
- **Plan asset versioning** to minimize cache invalidation needs

## 🐛 **Troubleshooting**

### **Common Issues**

#### **Access Denied**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify bucket access
./scripts/assets.sh info

# Test specific bucket
aws s3 ls s3://innerworld-dev-app-assets/
```

#### **CloudFront Not Working**
```bash
# Check if distribution ID is configured
./scripts/assets.sh info

# Update distribution ID in script
# Edit get_cloudfront_id() function in assets.sh
```

#### **Sync Issues**
```bash
# Use dry-run to debug
./scripts/assets.sh sync -d source destination

# Check AWS CLI version
aws --version

# Verify source and destination paths
./scripts/assets.sh list -e source
```

#### **Large File Uploads**
```bash
# Use verbose mode for debugging
./scripts/assets.sh -v upload ./large-files/

# Check file permissions
ls -la ./large-files/

# Consider file size limits (5GB per file for S3)
```

## 📊 **Monitoring & Analytics**

### **Asset Usage Tracking**

```bash
# Check asset sizes and counts
./scripts/assets.sh list -e prod -l --human-readable

# Compare asset growth over time
./scripts/assets.sh compare dev prod --summary-only

# Monitor CloudFront invalidations (check AWS console)
```

### **Cost Optimization**

- **S3 Storage**: ~$0.023/GB/month
- **CloudFront**: ~$0.085/GB transferred  
- **Invalidations**: $0.005 per path
- **API Requests**: $0.0004 per 1000 requests

**Cost-saving tips**:
- Use S3 lifecycle policies (already configured)
- Minimize CloudFront invalidations
- Compress assets before upload
- Remove unused assets regularly

---

## 📞 **Support**

For additional help:

1. **Script Help**: `./scripts/assets.sh help <command>`
2. **AWS Documentation**: [S3 User Guide](https://docs.aws.amazon.com/s3/)
3. **CloudFront Documentation**: [CloudFront User Guide](https://docs.aws.amazon.com/cloudfront/)
4. **AWS CLI Reference**: [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/)

**Quick Reference Card**:
```bash
# Upload      → ./scripts/assets.sh upload <path>
# Download    → ./scripts/assets.sh download [path] [local]
# List        → ./scripts/assets.sh list [-l] [path] 
# Sync        → ./scripts/assets.sh sync <from> <to>
# Compare     → ./scripts/assets.sh compare <env1> <env2>
# Info        → ./scripts/assets.sh info
```
