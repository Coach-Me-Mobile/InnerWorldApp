# ==============================================================================
# COGNITO MODULE
# ==============================================================================
# AWS Cognito User Pool and Identity Pool for InnerWorldApp authentication
# Supports Apple Sign-In and email/password authentication
# ==============================================================================

# ==============================================================================
# COGNITO USER POOL
# ==============================================================================

resource "aws_cognito_user_pool" "main" {
  name = "${var.name_prefix}-user-pool"

  # Username configuration
  username_attributes      = ["email"]
  auto_verified_attributes = var.email_verification_required ? ["email"] : []

  # Password policy
  password_policy {
    minimum_length                   = var.password_policy_min_length
    require_uppercase                = var.password_policy_require_uppercase
    require_lowercase                = var.password_policy_require_lowercase
    require_numbers                  = var.password_policy_require_numbers
    require_symbols                  = var.password_policy_require_symbols
    temporary_password_validity_days = 7
  }

  # MFA configuration - disabled for initial deployment
  mfa_configuration = "OFF"

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # User pool add-ons
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  # Device configuration
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Verification message template
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "InnerWorld - Verify your email"
    email_message        = "Welcome to InnerWorld! Your verification code is {####}. This code expires in 24 hours."
  }

  # User attributes
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 5
      max_length = 256
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "given_name"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "family_name"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

# birthdate is a standard Cognito attribute - no custom schema needed

  # Custom attributes for app-specific data
  schema {
    attribute_data_type = "String"
    name                = "user_preferences"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "consent_version"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 10
    }
  }

  # Lambda triggers for custom logic
  lambda_config {
    pre_sign_up         = var.enable_lambda_triggers ? aws_lambda_function.pre_signup[0].arn : null
    post_confirmation   = var.enable_lambda_triggers ? aws_lambda_function.post_confirmation[0].arn : null
    pre_authentication  = var.enable_lambda_triggers ? aws_lambda_function.pre_authentication[0].arn : null
    post_authentication = var.enable_lambda_triggers ? aws_lambda_function.post_authentication[0].arn : null
    custom_message      = var.enable_lambda_triggers ? aws_lambda_function.custom_message[0].arn : null
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-user-pool"
    Type = "CognitoUserPool"
  })
}

# ==============================================================================
# COGNITO USER POOL DOMAIN
# ==============================================================================

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.name_prefix}-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}

# ==============================================================================
# COGNITO USER POOL CLIENT (iOS App)
# ==============================================================================

resource "aws_cognito_user_pool_client" "ios_app" {
  name            = "${var.name_prefix}-ios-client"
  user_pool_id    = aws_cognito_user_pool.main.id
  generate_secret = false # Public client for mobile app

  # Allowed OAuth flows
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

  # Callback URLs for the iOS app
  callback_urls = [
    "innerworld://auth/callback",
    "com.gauntletai.innerworld://auth/callback"
  ]

  logout_urls = [
    "innerworld://auth/logout",
    "com.gauntletai.innerworld://auth/logout"
  ]

  # Supported identity providers
  supported_identity_providers = var.enable_apple_signin ? ["COGNITO", "SignInWithApple"] : ["COGNITO"]

  # Security settings - values are in their respective units
  refresh_token_validity = 30 # 30 days
  access_token_validity  = 1  # 1 hour
  id_token_validity      = 1  # 1 hour

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Token revocation
  enable_token_revocation = true

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Explicit auth flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Read and write attributes
  read_attributes = [
    "email",
    "email_verified",
    "given_name",
    "family_name",
    "birthdate",
    "custom:user_preferences",
    "custom:consent_version"
  ]

  write_attributes = [
    "email",
    "given_name",
    "family_name",
    "birthdate",
    "custom:user_preferences",
    "custom:consent_version"
  ]
}

# ==============================================================================
# APPLE SIGN-IN IDENTITY PROVIDER
# ==============================================================================

resource "aws_cognito_identity_provider" "apple" {
  count = var.enable_apple_signin ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "SignInWithApple"
  provider_type = "SignInWithApple"

  provider_details = {
    authorize_scopes = "email name"
    client_id        = var.apple_client_id
    team_id          = var.apple_team_id
    key_id           = var.apple_key_id
    private_key      = var.apple_private_key
  }

  # Attribute mapping
  attribute_mapping = {
    email       = "email"
    name        = "name"
    given_name  = "firstName"
    family_name = "lastName"
  }
}

# ==============================================================================
# COGNITO IDENTITY POOL
# ==============================================================================

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.name_prefix}-identity-pool"
  allow_unauthenticated_identities = false
  allow_classic_flow               = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.ios_app.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = true
  }

  # Apple Sign-In provider
  supported_login_providers = var.enable_apple_signin ? {
    "appleid.apple.com" = var.apple_client_id
  } : {}

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-identity-pool"
    Type = "CognitoIdentityPool"
  })
}

# ==============================================================================
# IAM ROLES FOR COGNITO IDENTITY POOL
# ==============================================================================

# Authenticated role
resource "aws_iam_role" "authenticated" {
  name = "${var.name_prefix}-cognito-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cognito-authenticated-role"
    Type = "IAMRole"
  })
}

# Unauthenticated role (minimal permissions)
resource "aws_iam_role" "unauthenticated" {
  name = "${var.name_prefix}-cognito-unauthenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "unauthenticated"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cognito-unauthenticated-role"
    Type = "IAMRole"
  })
}

# ==============================================================================
# IAM POLICIES FOR COGNITO ROLES
# ==============================================================================

# Policy for authenticated users
data "aws_iam_policy_document" "authenticated_policy" {
  # Allow access to user's own data in DynamoDB
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query"
    ]
    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${var.name_prefix}-*"
    ]
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "dynamodb:LeadingKeys"
      values   = ["$${cognito-identity.amazonaws.com:sub}"]
    }
  }

  # Allow access to user's own S3 prefix
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.name_prefix}-user-data/$${cognito-identity.amazonaws.com:sub}/*"
    ]
  }

  # Allow listing user's own S3 prefix
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.name_prefix}-user-data"
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["$${cognito-identity.amazonaws.com:sub}/*"]
    }
  }
}

resource "aws_iam_role_policy" "authenticated" {
  name   = "${var.name_prefix}-cognito-authenticated-policy"
  role   = aws_iam_role.authenticated.id
  policy = data.aws_iam_policy_document.authenticated_policy.json
}

# Policy for unauthenticated users (very limited)
data "aws_iam_policy_document" "unauthenticated_policy" {
  # Allow only basic AWS service calls for sign-up
  statement {
    effect = "Allow"
    actions = [
      "cognito-idp:SignUp",
      "cognito-idp:ConfirmSignUp",
      "cognito-idp:ResendConfirmationCode"
    ]
    resources = [
      aws_cognito_user_pool.main.arn
    ]
  }
}

resource "aws_iam_role_policy" "unauthenticated" {
  name   = "${var.name_prefix}-cognito-unauthenticated-policy"
  role   = aws_iam_role.unauthenticated.id
  policy = data.aws_iam_policy_document.unauthenticated_policy.json
}

# ==============================================================================
# COGNITO IDENTITY POOL ROLE ATTACHMENT
# ==============================================================================

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "authenticated"   = aws_iam_role.authenticated.arn
    "unauthenticated" = aws_iam_role.unauthenticated.arn
  }

  # Role mappings for different identity providers
  dynamic "role_mapping" {
    for_each = var.enable_apple_signin ? [1] : []
    content {
      identity_provider         = "appleid.apple.com"
      ambiguous_role_resolution = "AuthenticatedRole"
      type                      = "Rules"

      mapping_rule {
        claim      = "aud"
        match_type = "Equals"
        value      = var.apple_client_id
        role_arn   = aws_iam_role.authenticated.arn
      }
    }
  }
}

# ==============================================================================
# LAMBDA EXECUTION ROLE (for triggers)
# ==============================================================================

resource "aws_iam_role" "lambda_execution" {
  count = var.enable_lambda_triggers ? 1 : 0
  name  = "${var.name_prefix}-cognito-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cognito-lambda-execution-role"
    Type = "IAMRole"
  })
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count      = var.enable_lambda_triggers ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution[0].name
}

# ==============================================================================
# LAMBDA FUNCTIONS FOR COGNITO TRIGGERS (optional)
# ==============================================================================

# Pre-signup trigger
resource "aws_lambda_function" "pre_signup" {
  count = var.enable_lambda_triggers ? 1 : 0

  filename         = "${path.module}/cognito_triggers.zip"
  function_name    = "${var.name_prefix}-cognito-pre-signup"
  role             = aws_iam_role.lambda_execution[0].arn
  handler          = "pre_signup.handler"
  source_code_hash = data.archive_file.cognito_triggers[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cognito-pre-signup"
    Type = "LambdaFunction"
  })
}

# Post-confirmation trigger
resource "aws_lambda_function" "post_confirmation" {
  count = var.enable_lambda_triggers ? 1 : 0

  filename         = "${path.module}/cognito_triggers.zip"
  function_name    = "${var.name_prefix}-cognito-post-confirmation"
  role             = aws_iam_role.lambda_execution[0].arn
  handler          = "post_confirmation.handler"
  source_code_hash = data.archive_file.cognito_triggers[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cognito-post-confirmation"
    Type = "LambdaFunction"
  })
}

# Pre-authentication trigger
resource "aws_lambda_function" "pre_authentication" {
  count = var.enable_lambda_triggers ? 1 : 0

  filename         = "${path.module}/cognito_triggers.zip"
  function_name    = "${var.name_prefix}-cognito-pre-authentication"
  role             = aws_iam_role.lambda_execution[0].arn
  handler          = "pre_authentication.handler"
  source_code_hash = data.archive_file.cognito_triggers[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cognito-pre-authentication"
    Type = "LambdaFunction"
  })
}

# Post-authentication trigger
resource "aws_lambda_function" "post_authentication" {
  count = var.enable_lambda_triggers ? 1 : 0

  filename         = "${path.module}/cognito_triggers.zip"
  function_name    = "${var.name_prefix}-cognito-post-authentication"
  role             = aws_iam_role.lambda_execution[0].arn
  handler          = "post_authentication.handler"
  source_code_hash = data.archive_file.cognito_triggers[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cognito-post-authentication"
    Type = "LambdaFunction"
  })
}

# Custom message trigger
resource "aws_lambda_function" "custom_message" {
  count = var.enable_lambda_triggers ? 1 : 0

  filename         = "${path.module}/cognito_triggers.zip"
  function_name    = "${var.name_prefix}-cognito-custom-message"
  role             = aws_iam_role.lambda_execution[0].arn
  handler          = "custom_message.handler"
  source_code_hash = data.archive_file.cognito_triggers[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cognito-custom-message"
    Type = "LambdaFunction"
  })
}

# Lambda permission for Cognito to invoke functions
resource "aws_lambda_permission" "cognito_lambda" {
  count = var.enable_lambda_triggers ? 5 : 0

  statement_id = "AllowExecutionFromCognito${count.index}"
  action       = "lambda:InvokeFunction"
  function_name = [
    aws_lambda_function.pre_signup[0].function_name,
    aws_lambda_function.post_confirmation[0].function_name,
    aws_lambda_function.pre_authentication[0].function_name,
    aws_lambda_function.post_authentication[0].function_name,
    aws_lambda_function.custom_message[0].function_name
  ][count.index]
  principal  = "cognito-idp.amazonaws.com"
  source_arn = aws_cognito_user_pool.main.arn
}

# Create ZIP file for Lambda functions
data "archive_file" "cognito_triggers" {
  count = var.enable_lambda_triggers ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/cognito_triggers.zip"

  source {
    content = templatefile("${path.module}/cognito_triggers/pre_signup.py", {
      project_name = var.project_name
    })
    filename = "pre_signup.py"
  }

  source {
    content = templatefile("${path.module}/cognito_triggers/post_confirmation.py", {
      project_name = var.project_name
    })
    filename = "post_confirmation.py"
  }

  source {
    content = templatefile("${path.module}/cognito_triggers/pre_authentication.py", {
      project_name = var.project_name
    })
    filename = "pre_authentication.py"
  }

  source {
    content = templatefile("${path.module}/cognito_triggers/post_authentication.py", {
      project_name = var.project_name
    })
    filename = "post_authentication.py"
  }

  source {
    content = templatefile("${path.module}/cognito_triggers/custom_message.py", {
      project_name = var.project_name
    })
    filename = "custom_message.py"
  }
}
