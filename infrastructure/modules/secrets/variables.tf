# ==============================================================================
# SECRETS MODULE VARIABLES
# ==============================================================================
# Input variables for the secrets module
# ==============================================================================

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "recovery_window_days" {
  description = "Number of days to retain deleted secrets"
  type        = number
  default     = 7
}

variable "enable_secret_rotation" {
  description = "Enable automatic secret rotation"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# API KEYS AND CREDENTIALS (optional - will be set to placeholder if not provided)
# ==============================================================================

variable "openrouter_api_key" {
  description = "OpenRouter API key for LLM conversations and embeddings"
  type        = string
  default     = ""
  sensitive   = true
}

variable "neo4j_uri" {
  description = "Neo4j database URI"
  type        = string
  default     = ""
  sensitive   = true
}

variable "neo4j_username" {
  description = "Neo4j database username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "neo4j_password" {
  description = "Neo4j database password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "neo4j_database" {
  description = "Neo4j database name"
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_team_id" {
  description = "Apple Developer Team ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_key_id" {
  description = "Apple Sign-In Key ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_private_key" {
  description = "Apple Sign-In Private Key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "apple_client_id" {
  description = "Apple Sign-In Client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_store_connect_issuer_id" {
  description = "App Store Connect API Issuer ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_store_connect_key_id" {
  description = "App Store Connect API Key ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_store_connect_private_key" {
  description = "App Store Connect API Private Key"
  type        = string
  default     = ""
  sensitive   = true
}


