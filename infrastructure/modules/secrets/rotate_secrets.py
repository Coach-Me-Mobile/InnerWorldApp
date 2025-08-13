"""
Secret Rotation Lambda Function for InnerWorldApp
Handles automatic rotation of secrets in AWS Secrets Manager
"""

import json
import boto3
import os
import logging
from typing import Dict, Any

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
secrets_client = boto3.client('secretsmanager')

def handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Lambda handler for secret rotation
    
    Args:
        event: Lambda event containing secret rotation details
        context: Lambda context
    
    Returns:
        Response dictionary with status and details
    """
    try:
        logger.info(f"Starting secret rotation for project: {os.environ.get('PROJECT_NAME')}")
        
        # Get secret ARN from event
        secret_arn = event.get('SecretId')
        if not secret_arn:
            raise ValueError("SecretId not provided in event")
        
        # Get the step type
        step = event.get('Step', 'createSecret')
        
        logger.info(f"Processing step: {step} for secret: {secret_arn}")
        
        # Route to appropriate step handler
        if step == "createSecret":
            create_secret(secret_arn)
        elif step == "setSecret":
            set_secret(secret_arn)
        elif step == "testSecret":
            test_secret(secret_arn)
        elif step == "finishSecret":
            finish_secret(secret_arn)
        else:
            raise ValueError(f"Unknown step: {step}")
        
        logger.info(f"Successfully completed step: {step}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully completed {step} for secret rotation',
                'secretArn': secret_arn
            })
        }
        
    except Exception as e:
        logger.error(f"Error in secret rotation: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'secretArn': event.get('SecretId', 'unknown')
            })
        }

def create_secret(secret_arn: str) -> None:
    """Create a new version of the secret"""
    try:
        # Get current secret value
        current = secrets_client.get_secret_value(SecretId=secret_arn)
        current_secret = json.loads(current['SecretString'])
        
        # Generate new secret value based on type
        if 'api_key' in current_secret:
            # For API keys, we don't auto-rotate as they need manual intervention
            logger.info("API key detected - manual rotation required")
            return
            
        elif 'password' in current_secret:
            # Generate new password
            import secrets
            import string
            alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
            new_password = ''.join(secrets.choice(alphabet) for _ in range(32))
            current_secret['password'] = new_password
            
        elif 'key' in current_secret:
            # Generate new encryption key
            import secrets
            new_key = secrets.token_urlsafe(32)
            current_secret['key'] = new_key
            
        else:
            logger.warning(f"Unknown secret type for {secret_arn}")
            return
        
        # Update timestamp
        current_secret['created_at'] = str(datetime.utcnow().isoformat())
        
        # Put new secret version
        secrets_client.put_secret_value(
            SecretId=secret_arn,
            SecretString=json.dumps(current_secret),
            VersionStage='AWSPENDING'
        )
        
        logger.info("Created new secret version")
        
    except Exception as e:
        logger.error(f"Failed to create secret: {str(e)}")
        raise

def set_secret(secret_arn: str) -> None:
    """Set the secret in the service"""
    logger.info("Set secret step - no action needed for this implementation")

def test_secret(secret_arn: str) -> None:
    """Test the new secret"""
    try:
        # Get the pending secret value
        pending = secrets_client.get_secret_value(
            SecretId=secret_arn,
            VersionStage='AWSPENDING'
        )
        
        # Basic validation - ensure it's valid JSON
        secret_data = json.loads(pending['SecretString'])
        
        # Additional validation based on secret type
        if 'password' in secret_data:
            if len(secret_data['password']) < 8:
                raise ValueError("Password too short")
                
        elif 'key' in secret_data:
            if len(secret_data['key']) < 16:
                raise ValueError("Key too short")
        
        logger.info("Secret validation passed")
        
    except Exception as e:
        logger.error(f"Secret validation failed: {str(e)}")
        raise

def finish_secret(secret_arn: str) -> None:
    """Finish the rotation by updating version stages"""
    try:
        # Move AWSPENDING to AWSCURRENT
        secrets_client.update_secret_version_stage(
            SecretId=secret_arn,
            VersionStage='AWSCURRENT',
            MoveToVersionId=secrets_client.describe_secret(SecretId=secret_arn)['VersionIdsToStages'].get('AWSPENDING', [None])[0]
        )
        
        logger.info("Successfully finished secret rotation")
        
    except Exception as e:
        logger.error(f"Failed to finish rotation: {str(e)}")
        raise
