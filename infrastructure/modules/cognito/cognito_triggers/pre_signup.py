"""
Pre-signup Lambda trigger for Cognito User Pool
Validates and processes user registration before account creation
"""

import json
import logging
from typing import Dict, Any

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Pre-signup trigger handler
    
    Args:
        event: Cognito pre-signup event
        context: Lambda context
    
    Returns:
        Modified event with auto-confirm settings
    """
    try:
        logger.info(f"Pre-signup trigger for user: {event.get('userName', 'unknown')}")
        
        # Get user attributes
        user_attributes = event.get('request', {}).get('userAttributes', {})
        email = user_attributes.get('email', '')
        
        logger.info(f"Processing signup for email: {email}")
        
        # Age verification - ensure user is 13+
        birthdate = user_attributes.get('birthdate')
        if birthdate:
            if not validate_age(birthdate):
                logger.warning(f"Age validation failed for user: {email}")
                raise ValueError("Users must be 13 years or older to register")
        
        # Auto-confirm users for Apple Sign-In
        if event.get('triggerSource') == 'PreSignUp_ExternalProvider':
            event['response']['autoConfirmUser'] = True
            event['response']['autoVerifyEmail'] = True
            logger.info(f"Auto-confirming external provider user: {email}")
        
        # Set custom attributes
        event['response']['userAttributes'] = event['request']['userAttributes']
        
        # Add consent version tracking
        if 'custom:consent_version' not in event['response']['userAttributes']:
            event['response']['userAttributes']['custom:consent_version'] = '1.0'
        
        # Initialize user preferences
        if 'custom:user_preferences' not in event['response']['userAttributes']:
            default_preferences = json.dumps({
                'personas_enabled': ['courage', 'comfort', 'creative', 'compass'],
                'session_reminders': True,
                'data_retention_days': 30,
                'privacy_mode': 'standard'
            })
            event['response']['userAttributes']['custom:user_preferences'] = default_preferences
        
        logger.info(f"Successfully processed pre-signup for: {email}")
        return event
        
    except Exception as e:
        logger.error(f"Pre-signup validation failed: {str(e)}")
        # Return error to prevent user creation
        raise e

def validate_age(birthdate: str) -> bool:
    """
    Validate that user is at least 13 years old
    
    Args:
        birthdate: Birthdate in YYYY-MM-DD format
    
    Returns:
        True if user is 13+, False otherwise
    """
    try:
        from datetime import datetime, date
        
        birth_date = datetime.strptime(birthdate, '%Y-%m-%d').date()
        today = date.today()
        age = today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
        
        return age >= 13
        
    except (ValueError, TypeError):
        # If we can't parse the date, assume invalid
        return False
