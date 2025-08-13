"""
Post-authentication Lambda trigger for Cognito User Pool
Updates user session data and prepares context cache after successful authentication
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
    Post-authentication trigger handler
    
    Args:
        event: Cognito post-authentication event
        context: Lambda context
    
    Returns:
        Unmodified event (no response modifications needed)
    """
    try:
        user_id = event.get('userName', '')
        user_attributes = event.get('request', {}).get('userAttributes', {})
        email = user_attributes.get('email', '')
        trigger_source = event.get('triggerSource', '')
        
        logger.info(f"Post-authentication trigger for user: {user_id}, email: {email}, source: {trigger_source}")
        
        # Update user's last login information
        update_user_login_info(user_id, trigger_source)
        
        # Cache user context for conversation system
        cache_user_context(user_id, user_attributes)
        
        # Update session metrics
        update_session_metrics(user_id)
        
        logger.info(f"Post-authentication processing completed for user: {user_id}")
        return event
        
    except Exception as e:
        logger.error(f"Post-authentication processing failed for user {event.get('userName', 'unknown')}: {str(e)}")
        # Don't fail the authentication process, just log the error
        return event

def update_user_login_info(user_id: str, trigger_source: str) -> None:
    """
    Update user's last login information
    
    Args:
        user_id: Cognito user ID
        trigger_source: Authentication trigger source
    """
    try:
        import os
        from datetime import datetime
        
        table_name = f"{os.environ.get('PROJECT_NAME', 'innerworld')}-user-profiles"
        table = dynamodb.Table(table_name)
        
        # Update last login timestamp and login count
        response = table.update_item(
            Key={'user_id': user_id},
            UpdateExpression='SET last_login = :timestamp, login_count = if_not_exists(login_count, :zero) + :one, last_login_source = :source',
            ExpressionAttributeValues={
                ':timestamp': datetime.utcnow().isoformat(),
                ':zero': 0,
                ':one': 1,
                ':source': trigger_source
            },
            ReturnValues='UPDATED_NEW'
        )
        
        logger.info(f"Updated login info for user: {user_id}")
        
    except Exception as e:
        logger.error(f"Failed to update user login info: {str(e)}")

def cache_user_context(user_id: str, user_attributes: Dict[str, str]) -> None:
    """
    Cache user context for conversation system (placeholder for Neptune integration)
    
    Args:
        user_id: Cognito user ID
        user_attributes: User attributes from Cognito
    """
    try:
        import os
        
        # This would retrieve user's GraphRAG context from Neptune and cache it
        # for use during conversation sessions
        logger.info(f"Caching user context for: {user_id}")
        
        # Future implementation:
        # 1. Query Neptune for user's conversation history and context
        # 2. Build condensed context summary
        # 3. Cache in ElastiCache or DynamoDB with TTL
        # 4. Make available for conversation Lambda functions
        
        # For now, cache basic user preferences
        preferences = user_attributes.get('custom:user_preferences', '{}')
        try:
            preferences_data = json.loads(preferences)
        except json.JSONDecodeError:
            preferences_data = {}
        
        cache_data = {
            'user_id': user_id,
            'email': user_attributes.get('email', ''),
            'preferences': preferences_data,
            'cached_at': datetime.utcnow().isoformat(),
            'ttl': int(datetime.utcnow().timestamp()) + 3600  # 1 hour TTL
        }
        
        # Store in cache table
        table_name = f"{os.environ.get('PROJECT_NAME', 'innerworld')}-user-cache"
        table = dynamodb.Table(table_name)
        table.put_item(Item=cache_data)
        
        logger.info(f"Cached user context for: {user_id}")
        
    except Exception as e:
        logger.error(f"Failed to cache user context: {str(e)}")

def update_session_metrics(user_id: str) -> None:
    """
    Update session metrics for analytics
    
    Args:
        user_id: Cognito user ID
    """
    try:
        import os
        from datetime import datetime, date
        
        # Update daily login metrics
        table_name = f"{os.environ.get('PROJECT_NAME', 'innerworld')}-session-metrics"
        table = dynamodb.Table(table_name)
        
        today = date.today().isoformat()
        
        # Upsert daily metrics
        table.update_item(
            Key={
                'user_id': user_id,
                'date': today
            },
            UpdateExpression='SET login_count = if_not_exists(login_count, :zero) + :one, last_login = :timestamp',
            ExpressionAttributeValues={
                ':zero': 0,
                ':one': 1,
                ':timestamp': datetime.utcnow().isoformat()
            }
        )
        
        logger.info(f"Updated session metrics for user: {user_id}")
        
    except Exception as e:
        logger.error(f"Failed to update session metrics: {str(e)}")

from datetime import datetime
