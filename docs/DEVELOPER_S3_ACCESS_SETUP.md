# Developer S3 Access Setup Guide

Quick step-by-step guide to grant your developers access to InnerWorld S3 buckets.

## 🎯 **Quick Setup Process**

You have developer emails and need to grant them S3 access. Here's the fastest approach:

### **Option 1: Create IAM Group + Users (Recommended for Multiple Developers)**

This is the cleanest approach for managing multiple developers.

#### **Step 1: Create IAM Policy**

1. Go to **AWS Console** → **IAM** → **Policies** → **Create policy**
2. Click **JSON** tab and paste this policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3AssetAccess",
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
                "arn:aws:s3:::innerworld-prod-app-assets",
                "arn:aws:s3:::innerworld-prod-app-assets/*"
            ]
        },
        {
            "Sid": "S3ListAllBuckets",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudFrontInvalidation",
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

3. **Name**: `InnerWorldDeveloperS3Access`
4. **Description**: `S3 and CloudFront access for InnerWorld mobile app developers`
5. Click **Create policy**

#### **Step 2: Create IAM Group**

1. Go to **IAM** → **User groups** → **Create group**
2. **Group name**: `InnerWorldDevelopers`
3. **Attach permission policies**: Search and select `InnerWorldDeveloperS3Access`
4. Click **Create group**

#### **Step 3: Create IAM Users for Each Developer**

For each developer email, create a user:

1. Go to **IAM** → **Users** → **Create user**
2. **User name**: Use format like `john.doe` or `innerworld-dev-john`
3. **Access type**: Check ✅ **Provide user access to the AWS Management Console**
4. **Console password**: Choose **Custom password** and create a secure one
5. ✅ Check **Users must create a new password at next sign-in**
6. Click **Next**

#### **Step 4: Add Users to Group**

1. **Set permissions**: Choose **Add user to group**
2. Select ✅ **InnerWorldDevelopers** group
3. Click **Next** → **Create user**
4. **Important**: Save the login URL, username, and temporary password for each developer

#### **Step 5: Create Programmatic Access Keys**

For each user who needs script access:

1. Go to **IAM** → **Users** → Select user → **Security credentials** tab
2. **Access keys** section → **Create access key**
3. **Use case**: Choose **Command Line Interface (CLI)**
4. ✅ Check **I understand the above recommendation**
5. **Description tag**: `InnerWorld Asset Management`
6. Click **Create access key**
7. **⚠️ CRITICAL**: Copy and securely share the **Access Key ID** and **Secret Access Key**

### **Option 2: Single User with Shared Credentials (Quick & Simple)**

If you just want to get started quickly with one shared account:

1. **Create one IAM user**: `innerworld-developers`
2. **Attach policy directly**: `InnerWorldDeveloperS3Access` (from Step 1 above)
3. **Create access keys** and share with all developers
4. **Create console password** for AWS Console access

## 📨 **Developer Onboarding Email Template**

Send this to each developer:

```
Subject: InnerWorld S3 Asset Access - Setup Instructions

Hi [Developer Name],

You now have access to InnerWorld's S3 asset management system. Here's your setup:

## AWS Console Access (Optional)
- Login URL: https://[ACCOUNT-ID].signin.aws.amazon.com/console
- Username: [USERNAME]
- Temporary Password: [TEMP_PASSWORD]
- You'll be prompted to create a new password on first login

## Script Access (For asset.sh script)
- Access Key ID: [ACCESS_KEY_ID]
- Secret Access Key: [SECRET_ACCESS_KEY]
- Region: us-east-1

## Setup Instructions:

1. Configure AWS CLI:
   ```bash
   aws configure
   # Enter your Access Key ID
   # Enter your Secret Access Key
   # Default region: us-east-1
   # Default output format: json
   ```

2. Download and test the asset management script:
   ```bash
   # Download from project repo or get from team
   chmod +x assets.sh
   
   # Test your access
   ./assets.sh info
   
   # Upload test assets
   ./assets.sh upload ./my-test-images/
   ```

## S3 Bucket You Have Access To:
- Production: innerworld-prod-app-assets

## Quick Commands:
- Upload: `./assets.sh upload ./my-assets/`
- Download: `./assets.sh download`
- List: `./assets.sh list`
- Help: `./assets.sh --help`

## Documentation:
- Script Guide: docs/ASSET_MANAGEMENT_GUIDE.md
- Troubleshooting: docs/AWS_CONSOLE_DEVELOPER_ACCESS.md

Questions? Contact the development team.

Best regards,
[Your Name]
```

## 🔐 **Security Best Practices**

### **Access Key Management**
- ✅ **Share access keys securely** (encrypted email, Slack DM, password manager)
- ✅ **Set expiration reminders** for access keys (rotate every 90 days)
- ✅ **Monitor usage** in AWS CloudTrail
- ❌ **Never commit keys to git** or store in plain text

### **Production Environment Protection**
For extra security on production, create a separate policy:

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
                    "aws:RequestedRegion": "us-east-1"
                }
            }
        }
    ]
}
```

### **Group-Based Access Control**
Create separate groups for different access levels:

- **`InnerWorldDevelopers`**: Full dev/staging access, limited prod
- **`InnerWorldLeads`**: Full access to all environments
- **`InnerWorldDesigners`**: Upload-only access to dev/staging

## 🧪 **Testing Developer Access**

After setting up a developer, test their access:

```bash
# Have them run these commands
aws sts get-caller-identity
./assets.sh info
./assets.sh list
```

Expected output:
- ✅ AWS identity shows their username
- ✅ Script shows bucket access status
- ✅ Can list dev bucket contents

## 🔄 **Access Management Commands**

### **Add New Developer to Existing Group**
```bash
aws iam add-user-to-group \
  --group-name InnerWorldDevelopers \
  --user-name new-developer-username
```

### **Remove Developer Access**
```bash
aws iam remove-user-from-group \
  --group-name InnerWorldDevelopers \
  --user-name developer-username
```

### **List Group Members**
```bash
aws iam get-group --group-name InnerWorldDevelopers
```

### **Rotate Access Keys**
1. Create new access key for user
2. Share new key with developer
3. Have developer update their AWS CLI config
4. Delete old access key

## 🚨 **Troubleshooting Common Issues**

### **Developer Can't Access Buckets**
```bash
# Check if user is in group
aws iam get-groups-for-user --user-name developer-username

# Check group policies
aws iam list-attached-group-policies --group-name InnerWorldDevelopers

# Test direct S3 access
aws s3 ls s3://innerworld-dev-app-assets/ --profile developer-profile
```

### **Script Shows Access Denied**
1. **Verify AWS CLI configuration**: `aws configure list`
2. **Check credentials**: `aws sts get-caller-identity`
3. **Test bucket access**: `./assets.sh info`
4. **Check IAM permissions** in AWS Console

### **CloudFront Invalidation Fails**
- **Check CloudFront permissions** in the IAM policy
- **Verify distribution ID** is configured in the script
- **Check AWS region** (CloudFront is global but API calls are us-east-1)

## 📊 **Monitoring & Auditing**

### **Track S3 Usage**
```bash
# Check recent access logs
aws logs filter-log-events \
  --log-group-name /aws/s3/innerworld-dev-app-assets \
  --start-time $(date -d '1 day ago' +%s)000

# Get CloudTrail events for S3
aws logs filter-log-events \
  --log-group-name CloudTrail/S3DataEvents \
  --filter-pattern "{ $.eventSource = s3.amazonaws.com }"
```

### **Review Access Keys**
```bash
# List all access keys for a user
aws iam list-access-keys --user-name developer-username

# Check last used information
aws iam get-access-key-last-used --access-key-id AKIA...
```

---

## 📞 **Support Checklist**

When a developer reports access issues:

1. ✅ **Verify IAM user exists**
2. ✅ **Check group membership**
3. ✅ **Confirm policy is attached to group**
4. ✅ **Test AWS CLI configuration**
5. ✅ **Check access key status** (active/inactive)
6. ✅ **Verify bucket names** in script match actual buckets
7. ✅ **Test with different environment** (dev vs prod)

**Quick validation command for developers**:
```bash
./assets.sh info
```

This single command will show:
- ✅ AWS authentication status
- ✅ Bucket accessibility 
- ✅ CloudFront configuration
- ✅ Account information

---

**Need help?** Check `docs/AWS_CONSOLE_DEVELOPER_ACCESS.md` for detailed troubleshooting steps.
