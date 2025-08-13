"""
Custom message Lambda trigger for Cognito User Pool
Customizes email and SMS messages sent by Cognito
"""

import json
import logging
from typing import Dict, Any

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Custom message trigger handler
    
    Args:
        event: Cognito custom message event
        context: Lambda context
    
    Returns:
        Event with customized message content
    """
    try:
        user_id = event.get('userName', '')
        user_attributes = event.get('request', {}).get('userAttributes', {})
        trigger_source = event.get('triggerSource', '')
        
        logger.info(f"Custom message trigger for user: {user_id}, source: {trigger_source}")
        
        # Route to appropriate message customizer
        if trigger_source == 'CustomMessage_SignUp':
            customize_signup_message(event, user_attributes)
        elif trigger_source == 'CustomMessage_ResendCode':
            customize_resend_code_message(event, user_attributes)
        elif trigger_source == 'CustomMessage_ForgotPassword':
            customize_forgot_password_message(event, user_attributes)
        elif trigger_source == 'CustomMessage_UpdateUserAttribute':
            customize_update_attribute_message(event, user_attributes)
        elif trigger_source == 'CustomMessage_VerifyUserAttribute':
            customize_verify_attribute_message(event, user_attributes)
        elif trigger_source == 'CustomMessage_Authentication':
            customize_authentication_message(event, user_attributes)
        else:
            logger.warning(f"Unknown trigger source: {trigger_source}")
        
        logger.info(f"Custom message processed for user: {user_id}")
        return event
        
    except Exception as e:
        logger.error(f"Custom message processing failed for user {event.get('userName', 'unknown')}: {str(e)}")
        # Return original event if customization fails
        return event

def customize_signup_message(event: Dict[str, Any], user_attributes: Dict[str, str]) -> None:
    """
    Customize sign-up verification message
    
    Args:
        event: Cognito event
        user_attributes: User attributes
    """
    given_name = user_attributes.get('given_name', 'Friend')
    code_parameter = event['request']['codeParameter']
    
    event['response']['emailSubject'] = 'Welcome to InnerWorld - Verify Your Email'
    event['response']['emailMessage'] = f"""
    <html>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #4A90E2;">Welcome to InnerWorld, {given_name}! 🌟</h2>
            
            <p>Thank you for joining our community of teens exploring their inner world through meaningful conversations with AI personas.</p>
            
            <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                <h3 style="margin-top: 0;">Your Verification Code:</h3>
                <div style="font-size: 24px; font-weight: bold; color: #4A90E2; letter-spacing: 3px; text-align: center; padding: 10px; background: white; border-radius: 4px;">
                    {code_parameter}
                </div>
            </div>
            
            <p><strong>This code expires in 24 hours.</strong></p>
            
            <h3>What's Next?</h3>
            <ul>
                <li>🛡️ Complete age verification (13+ required)</li>
                <li>📋 Review our privacy policy and terms</li>
                <li>🎭 Meet your four personas: Courage, Comfort, Creative, and Compass</li>
                <li>💬 Start your first 20-minute reflection session</li>
            </ul>
            
            <div style="background-color: #fff3cd; padding: 15px; border-radius: 4px; margin: 20px 0;">
                <p style="margin: 0;"><strong>Remember:</strong> InnerWorld is designed for reflective journaling and personal growth. It's not therapy and should not replace professional mental health services.</p>
            </div>
            
            <p>Questions? We're here to help at support@innerworld.app</p>
            
            <p>Welcome to your inner world journey!</p>
            
            <hr style="border: 1px solid #eee; margin: 30px 0;">
            <p style="font-size: 12px; color: #666;">
                This email was sent to verify your InnerWorld account. If you didn't create this account, you can safely ignore this email.
            </p>
        </div>
    </body>
    </html>
    """

def customize_resend_code_message(event: Dict[str, Any], user_attributes: Dict[str, str]) -> None:
    """
    Customize resend verification code message
    
    Args:
        event: Cognito event
        user_attributes: User attributes
    """
    given_name = user_attributes.get('given_name', 'Friend')
    code_parameter = event['request']['codeParameter']
    
    event['response']['emailSubject'] = 'InnerWorld - Your New Verification Code'
    event['response']['emailMessage'] = f"""
    Hi {given_name},
    
    Here's your new verification code for InnerWorld:
    
    {code_parameter}
    
    This code expires in 24 hours.
    
    If you're having trouble with verification, please contact support@innerworld.app
    
    Best regards,
    The InnerWorld Team
    """

def customize_forgot_password_message(event: Dict[str, Any], user_attributes: Dict[str, str]) -> None:
    """
    Customize forgot password message
    
    Args:
        event: Cognito event
        user_attributes: User attributes
    """
    given_name = user_attributes.get('given_name', 'Friend')
    code_parameter = event['request']['codeParameter']
    
    event['response']['emailSubject'] = 'InnerWorld - Reset Your Password'
    event['response']['emailMessage'] = f"""
    Hi {given_name},
    
    We received a request to reset your InnerWorld password.
    
    Your password reset code is: {code_parameter}
    
    This code expires in 1 hour for security reasons.
    
    If you didn't request this password reset, you can safely ignore this email. Your password will remain unchanged.
    
    For security tips and account protection, visit our help center.
    
    Best regards,
    The InnerWorld Team
    """

def customize_update_attribute_message(event: Dict[str, Any], user_attributes: Dict[str, str]) -> None:
    """
    Customize update user attribute message
    
    Args:
        event: Cognito event
        user_attributes: User attributes
    """
    code_parameter = event['request']['codeParameter']
    
    event['response']['emailSubject'] = 'InnerWorld - Verify Your Email Change'
    event['response']['emailMessage'] = f"""
    Hi there,
    
    We received a request to update your email address for your InnerWorld account.
    
    Please use this verification code to confirm the change: {code_parameter}
    
    This code expires in 24 hours.
    
    If you didn't make this change, please contact support@innerworld.app immediately.
    
    Best regards,
    The InnerWorld Team
    """

def customize_verify_attribute_message(event: Dict[str, Any], user_attributes: Dict[str, str]) -> None:
    """
    Customize verify user attribute message
    
    Args:
        event: Cognito event
        user_attributes: User attributes
    """
    code_parameter = event['request']['codeParameter']
    
    event['response']['emailSubject'] = 'InnerWorld - Verify Your Information'
    event['response']['emailMessage'] = f"""
    Hi there,
    
    Please verify your information with this code: {code_parameter}
    
    This helps us keep your InnerWorld account secure and your data protected.
    
    The code expires in 24 hours.
    
    Best regards,
    The InnerWorld Team
    """

def customize_authentication_message(event: Dict[str, Any], user_attributes: Dict[str, str]) -> None:
    """
    Customize authentication message (for MFA)
    
    Args:
        event: Cognito event
        user_attributes: User attributes
    """
    code_parameter = event['request']['codeParameter']
    
    event['response']['emailSubject'] = 'InnerWorld - Your Login Code'
    event['response']['emailMessage'] = f"""
    Your InnerWorld login code is: {code_parameter}
    
    This code expires in 5 minutes.
    
    If you didn't try to log in, please secure your account and contact support@innerworld.app
    
    Best regards,
    The InnerWorld Team
    """
