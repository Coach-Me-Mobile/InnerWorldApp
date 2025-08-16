# AWS Console Developer Access Setup

## 🎯 **Quick Setup for S3 Asset Upload Access**

This guide shows how to grant developers S3 access via the AWS Console instead of Terraform.

## 📦 **S3 Buckets**

Your mobile app uses these buckets:
- **Dev**: `innerworld-dev-app-assets`
- **Staging**: `innerworld-staging-app-assets`
- **Prod**: `innerworld-prod-app-assets`

## 🔐 **Method 1: Create IAM User (Recommended)**

### **Step 1: Create IAM Policy**

1. Go to **IAM Console** → **Policies** → **Create policy**
2. Select **JSON** tab and paste this policy:

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
                "s3:GetObjectVersion",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::innerworld-dev-app-assets",
                "arn:aws:s3:::innerworld-dev-app-assets/*",
                "arn:aws:s3:::innerworld-staging-app-assets",
                "arn:aws:s3:::innerworld-staging-app-assets/*",
                "arn:aws:s3:::innerworld-prod-app-assets",
                "arn:aws:s3:::innerworld-prod-app-assets/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ],
            "Resource": "*"
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

3. **Name the policy**: `InnerWorldDeveloperS3Access`
4. **Description**: `S3 access for InnerWorld mobile app developers`
5. Click **Create policy**

### **Step 2: Create IAM User**

1. Go to **IAM Console** → **Users** → **Create user**
2. **Username**: `innerworld-developer-[name]` (e.g., `innerworld-developer-john`)
3. **Access type**: Select **Programmatic access**
4. Click **Next**

### **Step 3: Attach Policy**

1. **Attach policies directly** → Search for `InnerWorldDeveloperS3Access`
2. Select your policy and click **Next**
3. **Optional**: Add tags (Team, Environment, etc.)
4. Review and **Create user**

### **Step 4: Save Credentials**

⚠️ **Important**: Save the **Access Key ID** and **Secret Access Key** immediately - you won't see them again!

## 🏢 **Method 2: Create IAM Group (For Multiple Developers)**

### **Step 1: Create Group**

1. Go to **IAM Console** → **User groups** → **Create group**
2. **Group name**: `InnerWorldDevelopers`
3. **Attach permission policies** → Search for `InnerWorldDeveloperS3Access`
4. Select the policy and **Create group**

### **Step 2: Add Users to Group**

1. Go to the group → **Users** tab → **Add users**
2. Select existing users or create new ones
3. Click **Add users**

## 👤 **Method 3: Grant Access to Existing User**

If you have existing IAM users:

1. Go to **IAM Console** → **Users** → Select user
2. **Permissions** tab → **Add permissions**
3. **Attach policies directly** → Search for `InnerWorldDeveloperS3Access`
4. Select policy and **Add permissions**

## 🔧 **Developer Setup Instructions**

Send this to your developers:

### **Configure AWS CLI**

```bash
# Install AWS CLI (if not already installed)
# macOS:
brew install awscli

# Configure with provided credentials
aws configure
# AWS Access Key ID: [PROVIDED_ACCESS_KEY]
# AWS Secret Access Key: [PROVIDED_SECRET_KEY]
# Default region: us-west-2
# Default output format: json
```

### **Use the Asset Management Script**

```bash
# Download the unified asset management script
curl -O https://raw.githubusercontent.com/your-repo/scripts/assets.sh
chmod +x assets.sh

# Upload assets to dev environment
./assets.sh upload ./my-assets/

# Upload to production with CloudFront cache invalidation
./assets.sh upload -e prod -c ./production-assets/

# Download assets from production
./assets.sh download -e prod

# List assets in staging
./assets.sh list -e staging

# Sync between environments
./assets.sh sync dev staging

# Get help
./assets.sh --help
```

## 🔒 **Security Best Practices**

### **For Production Access**

Create a separate policy for production with additional restrictions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::innerworld-prod-app-assets",
                "arn:aws:s3:::innerworld-prod-app-assets/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "us-west-2"
                },
                "DateGreaterThan": {
                    "aws:CurrentTime": "2024-01-01T00:00:00Z"
                }
            }
        }
    ]
}
```

### **Additional Security Measures**

1. **MFA Requirement**: Add MFA condition for production access
2. **IP Restrictions**: Limit access to office IP ranges
3. **Time-based Access**: Set expiration dates for temporary developers
4. **Least Privilege**: Only grant access to specific S3 prefixes if needed

## 📋 **Access Matrix**

| Environment | Bucket Name | Access Level | CloudFront |
|-------------|-------------|--------------|------------|
| Dev | `innerworld-dev-app-assets` | Full | No |
| Staging | `innerworld-staging-app-assets` | Full | No |
| Prod | `innerworld-prod-app-assets` | Upload/Read | Yes |

## 🔍 **Troubleshooting**

### **Common Issues**

**"Access Denied" errors**:
```bash
# Check current user
aws sts get-caller-identity

# Test S3 access
aws s3 ls s3://innerworld-dev-app-assets/
```

**"Invalid credentials"**:
```bash
# Reconfigure AWS CLI
aws configure

# Or use a specific profile
aws configure --profile innerworld
```

**Script permission errors**:
```bash
# Make script executable
chmod +x upload-assets.sh

# Check script location
which upload-assets.sh
```

## 🚀 **CloudFront Setup (Production Only)**

If you haven't set up CloudFront yet, update the script with your distribution ID:

1. Go to **CloudFront Console**
2. Find your distribution for `innerworld-prod-app-assets`
3. Copy the **Distribution ID** (e.g., `E1234567890ABC`)
4. Update `upload-assets.sh`:

```bash
# Line 19 in the script
CLOUDFRONT_DISTRIBUTIONS[prod]="E1234567890ABC"  # Your actual ID
```

## 📞 **Support**

For help with:
- **AWS Console access**: Contact your AWS administrator
- **Upload script issues**: Check the script's built-in help with `--help`
- **S3 bucket permissions**: Verify the IAM policy is correctly attached

---

## 📋 **Script Options**

### **Full Featured Script** (`upload-assets.sh`)
- CloudFront invalidation support (production only)
- Content-type detection
- Verbose logging and dry-run modes

### **Simple Script** (`simple-upload.sh`)  
- Basic S3 sync without CloudFront complexity
- Faster and simpler for most use cases

**Quick Commands Summary**:
```bash
# Simple uploads (recommended for most cases)
./simple-upload.sh ./assets/                    # Dev environment
./simple-upload.sh -e prod ./assets/            # Production (CDN cache may take 24h to update)

# Full featured uploads (when you need immediate cache invalidation)
./upload-assets.sh -e prod -c ./assets/         # Production with immediate cache clear
./upload-assets.sh -d ./assets/                 # Dry run test

# Upload to specific path
./simple-upload.sh -t images/ ./icon-files/
```

**When to use each**:
- **Simple script**: Regular development, staging, most production uploads
- **Full script**: Critical production updates that need immediate global visibility
