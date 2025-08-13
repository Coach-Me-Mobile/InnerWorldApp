"""
Post-confirmation Lambda trigger for Cognito User Pool
Initializes user data and sets up user context after account confirmation
"""

import json
import logging
import boto3
from typing import Dict, Any

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')

def handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Post-confirmation trigger handler
    
    Args:
        event: Cognito post-confirmation event
        context: Lambda context
    
    Returns:
        Unmodified event (no response modifications needed)
    """
    try:
        user_id = event.get('userName', '')
        user_attributes = event.get('request', {}).get('userAttributes', {})
        email = user_attributes.get('email', '')
        
        logger.info(f"Post-confirmation trigger for user: {user_id}, email: {email}")
        
        # Initialize user profile in DynamoDB
        initialize_user_profile(user_id, user_attributes)
        
        # Set up initial GraphRAG context (placeholder for Neptune integration)
        initialize_graph_context(user_id, user_attributes)
        
        # Send welcome notification (optional)
        send_welcome_notification(email, user_attributes)
        
        logger.info(f"Successfully initialized user: {user_id}")
        return event
        
    except Exception as e:
        logger.error(f"Post-confirmation processing failed for user {event.get('userName', 'unknown')}: {str(e)}")
        # Don't fail the confirmation process, just log the error
        return event

def initialize_user_profile(user_id: str, user_attributes: Dict[str, str]) -> None:
    """
    Initialize user profile in DynamoDB
    
    Args:
        user_id: Cognito user ID
        user_attributes: User attributes from Cognito
    """
    try:
        table_name = f"{os.environ.get('PROJECT_NAME', 'innerworld')}-user-profiles"
        table = dynamodb.Table(table_name)
        
        # Parse user preferences
        preferences = user_attributes.get('custom:user_preferences', '{}')
        try:
            preferences_data = json.loads(preferences)
        except json.JSONDecodeError:
            preferences_data = {
                'personas_enabled': ['courage', 'comfort', 'creative', 'compass'],
                'session_reminders': True,
                'data_retention_days': 30,
                'privacy_mode': 'standard'
            }
        
        # Create user profile
        profile_item = {
            'user_id': user_id,
            'email': user_attributes.get('email', ''),
            'given_name': user_attributes.get('given_name', ''),
            'family_name': user_attributes.get('family_name', ''),
            'birthdate': user_attributes.get('birthdate', ''),
            'preferences': preferences_data,
            'consent_version': user_attributes.get('custom:consent_version', '1.0'),
            'created_at': datetime.utcnow().isoformat(),
            'last_updated': datetime.utcnow().isoformat(),
            'status': 'active',
            'session_count': 0,
            'total_conversation_time': 0
        }
        
        table.put_item(Item=profile_item)
        logger.info(f"Created user profile for: {user_id}")
        
    except Exception as e:
        logger.error(f"Failed to initialize user profile: {str(e)}")
        # Don't raise - we don't want to fail confirmation

def initialize_graph_context(user_id: str, user_attributes: Dict[str, str]) -> None:
    """
    Initialize GraphRAG context for the user (placeholder for Neptune integration)
    
    Args:
        user_id: Cognito user ID
        user_attributes: User attributes from Cognito
    """
    try:
        # This would connect to Neptune and create initial user node
        # For now, just log the intent
        logger.info(f"Would initialize GraphRAG context for user: {user_id}")
        
        # Future implementation:
        # - Create user node in Neptune
        # - Set up initial context structure
        # - Initialize persona preferences
        
    except Exception as e:
        logger.error(f"Failed to initialize graph context: {str(e)}")

def send_welcome_notification(email: str, user_attributes: Dict[str, str]) -> None:
    """
    Send welcome notification to new user
    
    Args:
        email: User email address
        user_attributes: User attributes from Cognito
    """
    try:
        # This would send a welcome email or push notification
        # For now, just log the intent
        logger.info(f"Would send welcome notification to: {email}")
        
        # Future implementation:
        # - Send welcome email
        # - Set up push notification preferences
        # - Schedule onboarding reminders
        
    except Exception as e:
        logger.error(f"Failed to send welcome notification: {str(e)}")

import os
from datetime import datetime
