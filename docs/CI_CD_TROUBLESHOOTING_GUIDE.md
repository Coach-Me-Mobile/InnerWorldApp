# CI/CD Troubleshooting Guide

## GitHub Actions iOS Pipeline

### Common Issues and Solutions

#### 1. Bundle Identifier Missing Error

**Error:**
```
Bundle identifier is missing. InnerWorld doesn't have a bundle identifier. 
Add a value for PRODUCT_BUNDLE_IDENTIFIER in the build settings editor.
```

**Cause:**
The xcodebuild command requires a bundle identifier to be specified, but the variable containing it was not defined in the workflow.

**Solution:**
The bundle identifier is defined in the workflow as an environment variable since it's not sensitive information:

```yaml
# Set bundle identifier (not a secret, so we can define it here)
BUNDLE_ID="com.thoughtmanifold.InnerWorld"
```

Then use it in the xcodebuild command:
```yaml
PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID"
```

**Best Practice Notes:**
- Bundle identifiers are not secrets (they're public in the App Store)
- They should be treated as configuration values, not secrets
- Define them as environment variables in the workflow or store in AWS Parameter Store
- Do NOT store them in AWS Secrets Manager (reserved for actual secrets)

#### 2. AWS Secrets Manager Integration

**Configuration:**
The workflow uses AWS Secrets Manager in `us-west-2` region to retrieve:
- Apple Sign-In credentials: `innerworld-prod/apple/signin-key`
- App Store Connect API credentials: `innerworld-prod/appstoreconnect/api-key`

**Required Secrets Structure:**
```json
// innerworld-prod/apple/signin-key
{
  "team_id": "YOUR_APPLE_TEAM_ID",
  "client_id": "YOUR_APPLE_CLIENT_ID"
}

// innerworld-prod/appstoreconnect/api-key
{
  "key_id": "YOUR_KEY_ID",
  "issuer_id": "YOUR_ISSUER_ID",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
}
```

#### 3. Code Signing Strategy

The workflow supports multiple signing strategies:
1. **Automatic signing with App Store Connect API** (recommended)
   - Requires valid team ID and App Store Connect API credentials
   - No manual certificates needed
2. **Manual signing with certificates**
   - Requires certificates in GitHub secrets
   - Fallback when API credentials unavailable
3. **No signing** (build verification only)
   - When no credentials are available

### Debugging Tips

1. **Enable debug logging:**
   Add `ACTIONS_STEP_DEBUG` secret with value `true` in repository settings

2. **Check AWS credentials:**
   Verify the GitHub Actions AWS user has permissions to access Secrets Manager

3. **Validate secret formats:**
   Ensure JSON secrets are properly formatted and keys match expected names

4. **Monitor workflow runs:**
   Review the workflow output for validation messages about credentials

### Related Documentation
- [GitHub Actions Setup Guide](./GITHUB_ACTIONS_SETUP.md)
- [AWS Console Developer Access](./AWS_CONSOLE_DEVELOPER_ACCESS.md)
- [Manual Deployment Guide](./MANUAL_DEPLOYMENT_GUIDE.md)