# Architecture Images

This directory contains visual diagrams for the InnerWorld infrastructure documentation.

## Required Images

### infrastructure-architecture.png
- **Purpose**: Main infrastructure architecture diagram for README
- **Source**: Professional AWS architecture diagram
- **Requirements**: 
  - High resolution (1200px+ width recommended)
  - Clear service labels and connections
  - Color-coded by service type
  - Shows cost annotations
  - Displays all major components:
    - iOS VR App client
    - AWS Cognito authentication
    - WebSocket API Gateway with JWT auth
    - Lambda functions (Connect, Disconnect, Conversation, Health)
    - Neptune GraphRAG cluster (Primary + Reader)
    - DynamoDB tables (LiveConversations, WebSocketConnections, SessionContext)
    - External APIs (OpenRouter, Apple Authentication)
    - AWS Secrets Manager
    - CloudWatch monitoring
    - VPC networking (Public/Private subnets, NAT Gateways)

**To add this image:**
1. Save your professional architecture diagram as `infrastructure-architecture.png`
2. Place it in this directory (`docs/images/`)
3. The infrastructure README will automatically display it

## Image Guidelines

- Use PNG format for diagrams with transparency
- Optimize file size while maintaining clarity
- Include alt text descriptions in README references
- Keep images under 5MB for fast loading
- Use consistent visual style across diagrams
