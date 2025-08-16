# InnerWorld Asset Management Guide

## 🎯 **One-Stop-Shop Asset Management**

The unified `assets.sh` script provides complete asset management for your mobile app across all environments.

### **📦 Quick Start**

```bash
# Make script executable (one-time setup)
chmod +x scripts/assets.sh

# Upload assets to production
./scripts/assets.sh upload ./my-assets/

# Download all production assets (unpacked at the path iOS app expects)
./scripts/assets.sh download assets

# List assets in production
./scripts/assets.sh list

# Sync from production to local backup
./scripts/assets.sh sync prod ./backup/

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
-t, --target PATH    Target S3 path prefix [default: assets/]
-c, --invalidate     Invalidate CloudFront cache after upload
-d, --dry-run        Preview what would be uploaded
--delete             Delete extraneous files from destination

# Examples
./scripts/assets.sh upload ./images/                    # Upload to prod/assets/
./scripts/assets.sh upload -c ./icons/                  # Upload to prod + invalidate cache
./scripts/assets.sh upload -t images/ ./new-logos/      # Upload to prod/images/
./scripts/assets.sh upload -d ./assets/                 # Preview upload (dry run)
```

### **🔽 Download Assets**

Download assets from S3 to local directory.

```bash
# Basic usage
./scripts/assets.sh download [remote_path] [local_path]

# Options
-d, --dry-run        Preview what would be downloaded
--delete             Delete extraneous local files

# Arguments
remote_path          S3 path to download (optional, defaults to entire bucket)
local_path           Local destination path [default: ./ios/InnerWorld/InnerWorldRoom/Sources/InnerWorldRoom/InnerWorldRoom.rkassets/]

# Examples
./scripts/assets.sh download                            # Download all prod assets to iOS directory
./scripts/assets.sh download images/ ./my-images/       # Download specific folder
./scripts/assets.sh download assets/logo.png ./         # Download specific file
./scripts/assets.sh download -d                         # Preview download (dry run)
```

### **📋 List/Browse Assets**

Browse and explore assets in S3 buckets.

```bash
# Basic usage
./scripts/assets.sh list [path]

# Options
-l, --long           Show detailed information (size, date)
-r, --recursive      List all files recursively
--human-readable     Show file sizes in human readable format

# Examples
./scripts/assets.sh list                                # List root of prod bucket
./scripts/assets.sh list -l                             # Detailed list of prod
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
./scripts/assets.sh sync prod ./backup/                 # Download from prod to local backup
./scripts/assets.sh sync ./local-assets/ prod           # Upload from local to prod
./scripts/assets.sh sync ./backup/ ./restore/           # Local to local sync
./scripts/assets.sh sync -d ./assets/ prod              # Preview sync (dry run)
```

### **⚖️ Compare Assets**

**Note**: Compare functionality is limited as only production environment exists.

```bash
# Suggested workflow for asset comparison:
# 1. Download current production
./scripts/assets.sh download ./current-prod/

# 2. Compare with iOS assets
diff -r ./current-prod/ ./ios/InnerWorld/InnerWorldRoom/Sources/InnerWorldRoom/InnerWorldRoom.rkassets/

# 3. Upload changes if needed
./scripts/assets.sh upload ./ios/InnerWorld/InnerWorldRoom/Sources/InnerWorldRoom/InnerWorldRoom.rkassets/
```

### **ℹ️ System Info**

Display bucket status, CloudFront configuration, and AWS authentication info.

```bash
./scripts/assets.sh info
```

## 🏗️ **Infrastructure Overview**

### **S3 Bucket**
- **Production**: `innerworld-prod-app-assets` (CloudFront CDN)
  - Region: `us-west-2`
  - Access: Direct S3 or CloudFront CDN

### **Access Pattern**
- **Production**: Direct S3 URLs or CloudFront CDN (when configured)

### **CloudFront Caching**
- **Default TTL**: 1 hour (3600 seconds)
- **Assets TTL**: 1 day to 1 year (configurable)
- **Cache Invalidation**: Available for production updates

## 📱 **Mobile App Integration**

### **Asset URL Patterns**

```swift
// Production (Direct S3)
let prodS3URL = "https://innerworld-prod-app-assets.s3.us-west-2.amazonaws.com/assets/logo.png"

// Production (CloudFront CDN - when configured)
let prodCDNURL = "https://YOUR_CLOUDFRONT_DISTRIBUTION.cloudfront.net/assets/logo.png"
```

### **Asset Loading**

```swift
func getAssetURL(path: String) -> String {
    // Currently only production environment is available
    // Update with your CloudFront distribution ID when configured
    return "https://innerworld-prod-app-assets.s3.us-west-2.amazonaws.com/\(path)"
    // Or if CloudFront is configured:
    // return "https://YOUR_CLOUDFRONT_DISTRIBUTION.cloudfront.net/\(path)"
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
# Default region: us-west-2
# Default output format: json

# Test access
./scripts/assets.sh info
```

## 🚀 **Common Workflows**

### **🎨 Design Asset Updates**

```bash
# 1. Upload new designs to production (use dry-run first for safety)
./scripts/assets.sh upload -d -t designs/ ./new-designs/

# 2. If dry-run looks good, upload for real
./scripts/assets.sh upload -t designs/ ./new-designs/

# 3. If CloudFront is configured, invalidate cache
./scripts/assets.sh upload -c -t designs/ ./new-designs/
```

### **📦 App Release Preparation**

```bash
# 1. Download production backup before changes
./scripts/assets.sh download ./backup-$(date +%Y%m%d)/

# 2. Preview changes with dry-run
./scripts/assets.sh upload -d ./v2.0-assets/

# 3. Upload release assets with cache invalidation (if CloudFront configured)
./scripts/assets.sh upload -c ./v2.0-assets/

# 4. Verify upload completed
./scripts/assets.sh list -l | grep v2.0
```

### **🔍 Asset Debugging**

```bash
# 1. List all assets to find the problematic one
./scripts/assets.sh list -r | grep logo

# 2. Download specific asset for inspection
./scripts/assets.sh download assets/logo.png ./debug/

# 3. Compare with local version
diff ./debug/logo.png ./local-assets/logo.png

# 4. Re-upload fixed version
./scripts/assets.sh upload -c -t assets/ ./fixed-logo.png
```

### **🧹 Environment Cleanup**

```bash
# 1. Download current production to local
./scripts/assets.sh download ./current-state/

# 2. Preview what sync would change
./scripts/assets.sh sync -d --delete ./new-assets/ prod

# 3. Clean sync to production (removes extra files)
./scripts/assets.sh sync --delete ./new-assets/ prod
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
# Info        → ./scripts/assets.sh info

# Note: All operations work with production environment only
# Default download path: ./ios/InnerWorld/InnerWorldRoom/Sources/InnerWorldRoom/InnerWorldRoom.rkassets/
```
