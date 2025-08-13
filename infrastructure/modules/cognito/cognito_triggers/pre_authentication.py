"""
Pre-authentication Lambda trigger for Cognito User Pool
Validates and logs authentication attempts before allowing sign-in
"""

import json
import logging
import boto3
from typing import Dict, Any

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Pre-authentication trigger handler
    
    Args:
        event: Cognito pre-authentication event
        context: Lambda context
    
    Returns:
        Event (unmodified, or with error if authentication should be blocked)
    """
    try:
        user_id = event.get('userName', '')
        user_attributes = event.get('request', {}).get('userAttributes', {})
        email = user_attributes.get('email', '')
        trigger_source = event.get('triggerSource', '')
        
        logger.info(f"Pre-authentication trigger for user: {user_id}, email: {email}, source: {trigger_source}")
        
        # Check if user account is in good standing
        if not validate_user_status(user_id, user_attributes):
            logger.warning(f"Authentication blocked for user: {user_id}")
            raise ValueError("Account access has been restricted. Please contact support.")
        
        # Log authentication attempt for security monitoring
        log_authentication_attempt(user_id, trigger_source, success=True)
        
        logger.info(f"Pre-authentication validation passed for user: {user_id}")
        return event
        
    except Exception as e:
        logger.error(f"Pre-authentication failed for user {event.get('userName', 'unknown')}: {str(e)}")
        
        # Log failed attempt
        try:
            log_authentication_attempt(event.get('userName', ''), event.get('triggerSource', ''), success=False, error=str(e))
        except:
            pass
        
        # Re-raise to block authentication
        raise e

def validate_user_status(user_id: str, user_attributes: Dict[str, str]) -> bool:
    """
    Validate that the user account is in good standing
    
    Args:
        user_id: Cognito user ID
        user_attributes: User attributes from Cognito
    
    Returns:
        True if user can authenticate, False otherwise
    """
    try:
        # Check for account suspension flags
        # This could check DynamoDB for user status, suspension flags, etc.
        
        # For now, just check basic requirements
        email = user_attributes.get('email', '')
        if not email:
            logger.warning(f"User {user_id} missing email attribute")
            return False
        
        # Check if email is verified (for email sign-ins)
        email_verified = user_attributes.get('email_verified', 'false').lower() == 'true'
        if not email_verified:
            logger.warning(f"User {user_id} email not verified")
            # Allow through for Apple Sign-In, but not for email sign-in
            # The trigger source will help determine this
        
        # Additional validations could include:
        # - Check for banned/suspended users
        # - Validate subscription status
        # - Check for terms of service acceptance
        # - Rate limiting checks
        
        return True
        
    except Exception as e:
        logger.error(f"User status validation failed: {str(e)}")
        return False

def log_authentication_attempt(user_id: str, trigger_source: str, success: bool, error: str = None) -> None:
    """
    Log authentication attempt for security monitoring
    
    Args:
        user_id: Cognito user ID
        trigger_source: Authentication trigger source
        success: Whether authentication was successful
        error: Error message if authentication failed
    """
    try:
        import os
        from datetime import datetime
        
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'user_id': user_id,
            'trigger_source': trigger_source,
            'success': success,
            'project': os.environ.get('PROJECT_NAME', 'innerworld'),
            'environment': os.environ.get('ENVIRONMENT', 'unknown')
        }
        
        if error:
            log_entry['error'] = error
        
        # This could be sent to CloudWatch, DynamoDB, or other monitoring service
        logger.info(f"Authentication attempt logged: {json.dumps(log_entry)}")
        
        # Future implementation:
        # - Store in DynamoDB for analytics
        # - Send to CloudWatch custom metrics
        # - Alert on suspicious patterns
        
    except Exception as e:
        logger.error(f"Failed to log authentication attempt: {str(e)}")
        # Don't fail authentication due to logging issues
