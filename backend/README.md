# InnerWorld Backend - Phase 1

Basic serverless backend foundation for the InnerWorld AR app, implementing only the core Phase 1 requirements.

## Phase 1 Scope

This implementation covers **only** Darren's Phase 1 tasks:
- ✅ Basic Lambda function structure (conversation handler + health check)
- ✅ OpenRouter API client for LLM conversations
- ✅ OpenAI API client for text embeddings  
- ✅ Mock Neptune connection layer
- ✅ Local development environment

## Quick Start

### Prerequisites
- Go 1.21+
- Docker Desktop
- Optional: OpenRouter & OpenAI API keys

### Setup
```bash
cd backend/
make setup          # Initial setup
make dev-start      # Start development environment
make build          # Build Lambda functions
make test-conversation  # Test basic conversation
```

## Architecture

```
backend/
├── cmd/
│   ├── conversation-handler/  # Basic conversation Lambda
│   └── health-check/         # Health monitoring Lambda
├── internal/
│   ├── config/              # Basic configuration
│   ├── embeddings/          # OpenAI client
│   ├── graph/               # Neptune interface + mock
│   ├── llm/                 # OpenRouter client
│   └── types/               # Basic data structures
└── docker-compose.yml       # LocalStack
```

## Core Components

### Conversation Handler
- Processes basic conversation requests via API Gateway
- Integrates with OpenRouter for LLM responses
- Uses mock responses when API keys not configured
- Simple request/response format

### Health Check
- Monitors system connectivity
- Tests Neptune mock client
- Returns service status

### OpenRouter Integration
- Basic LLM conversation client
- Simple system prompt (no personas)
- Error handling and fallback responses

### Mock Neptune
- Development-only Neptune client
- Basic user context storage
- Ready for real Neptune integration

### Configuration
- Environment-aware settings
- Optional API keys for development
- Production validation

## API Examples

### Conversation Request
```json
{
  "message": "Hello!",
  "userId": "user-123"
}
```

### Response
```json
{
  "messageId": "uuid-here",
  "content": "Hello! I'm here to support you.",
  "timestamp": "2024-01-15T10:00:00Z"
}
```

## Development

```bash
make help           # Show all commands
make dev-start      # Start environment
make build          # Build functions
make test-conversation  # Test real OpenRouter conversation!
make test-health    # Test complete health check system
make test-services  # Check LocalStack status
make clean         # Clean up
```

## Integration Ready

This Phase 1 implementation provides:
- **Clean interfaces** for Neptune integration
- **Configuration patterns** for AWS deployment
- **Basic Lambda structure** ready for Terraform
- **Mock implementations** for independent development

## Next Phases

- **Phase 2**: WebSocket API, conversation storage, session management
- **Phase 3**: Frontend integration, authentication
- **Phase 4**: Personas, safety moderation, advanced features

---

**Status: Phase 1 Complete ✅**  
**Ready for**: Infrastructure integration and Phase 2 development