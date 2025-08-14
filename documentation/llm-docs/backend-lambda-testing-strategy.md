# Backend Lambda Testing Strategy

**InnerWorld Phase 2 - Comprehensive Testing Architecture**

---

## 🎯 Testing Philosophy

Our testing strategy follows the principle of **"Right Tool for Each Job"** - using the most appropriate testing approach for each validation need:

- **Unit Tests**: Fast, isolated component validation
- **Component Tests**: Business logic workflow validation  
- **Integration Tests**: Infrastructure and AWS service validation

This approach maximizes **development velocity** while ensuring **comprehensive coverage** with **minimal redundancy**.

---

## 🏗️ Three-Tier Testing Architecture

```mermaid
flowchart TD
    subgraph "🏗️ Testing Pyramid"
        I[🐳 Integration Tests<br/>LocalStack + Docker<br/>~30s]
        C[🎯 Component Tests<br/>Go Mocks<br/>~3s]  
        U[📋 Unit Tests<br/>Pure Go<br/>~2s]
    end
    
    subgraph "📊 Coverage Areas"
        I --> I1[AWS Services]
        I --> I2[Infrastructure]
        I --> I3[SDK Integration]
        
        C --> C1[Business Logic]
        C --> C2[Conversation Flow]  
        C --> C3[Safety Systems]
        
        U --> U1[Individual Functions]
        U --> U2[Type Validation]
        U --> U3[Component Isolation]
    end
    
    subgraph "⚡ Performance"
        U --> Fast[⚡ 2 seconds]
        C --> Medium[🚀 3 seconds]
        I --> Slow[🐌 30 seconds]
    end
```

---

## 📋 Unit Tests - Pure Go Isolation

**Purpose**: Validate individual components in complete isolation

### What We Test
- ✅ Configuration loading and validation (`internal/config`)
- ✅ OpenAI embeddings client (`internal/embeddings`)
- ✅ OpenRouter LLM client (`internal/llm`)
- ✅ Conversation type validation (`internal/types`)
- ✅ Core component functionality

### How to Run
```bash
./scripts/test-unit.sh
```

### Technical Details
- **Speed**: ~2 seconds
- **Dependencies**: None (Pure Go)
- **Environment**: Any machine with Go installed
- **Reliability**: 100% consistent results

### What You'll See
```
=== InnerWorld Unit Tests ===
Testing individual components in isolation

Running Go unit tests...
=== RUN   TestLoadConfig
--- PASS: TestLoadConfig (0.00s)
=== RUN   TestNewOpenAIEmbeddingsClient  
--- PASS: TestNewOpenAIEmbeddingsClient (0.00s)
...
✅ Unit tests complete!
```

### When to Use
- 🔄 **Every code change** - fastest feedback loop
- 🐛 **Debugging individual components** 
- 📦 **CI/CD pipeline** - reliable and fast
- 👥 **New team member onboarding**

---

## 🎯 Component Tests - Business Logic Validation

**Purpose**: Test complete conversation workflows using mock services

### What We Test
✅ **Complete 6-Step Conversation Pipeline**:
1. **Setup**: All components initialized properly
2. **WebSocket Connect**: Neptune context loading and DynamoDB caching
3. **Message Processing**: Bidirectional safety checks (input + output)
4. **System Prompt Context**: Persona injection with user-specific context  
5. **DynamoDB Storage**: Message persistence with 24-hour TTL verification
6. **WebSocket Disconnect**: Resource cleanup and session processing

### How to Run
```bash
./scripts/test-e2e-conversation.sh
```

### Technical Details
- **Speed**: ~3 seconds
- **Dependencies**: None (Pure Go with mocks)
- **Environment**: Any machine with Go installed
- **Coverage**: Full conversation workflow

### What You'll See
```
=== InnerWorld End-to-End Conversation Flow Test ===

🔧 1. SETUP - Initializing all components...
   ✅ Mock DynamoDB client initialized
   ✅ Mock Neptune client initialized
   ✅ LangChain conversation chain initialized

🔌 2. WEBSOCKET CONNECT - Loading user context from Neptune...
   ✅ Loaded user context from Neptune: 3 context fields
   ✅ Cached context in DynamoDB with 1-hour TTL

💬 3. SEND MESSAGES - Processing conversation with safety checks...
   ✅ Input safety check: PASSED
   ✅ Output safety check: PASSED
   📥 AI Response: "I'm here to listen and support you..."
   💾 Messages stored in DynamoDB (user + AI)

🎭 4. SYSTEM PROMPT CONTEXT - Verifying persona context injection...
   ✅ Persona prompt generated: 802 characters
   📝 Context injected into system prompt

💾 5. DYNAMODB VERIFICATION - Reading stored messages...
   ✅ Retrieved 6 stored messages from DynamoDB
   ✅ TTL verification: Messages expire in 24.0 hours

🔌 6. WEBSOCKET DISCONNECT - Cleanup and session end processing...
   ✅ Resources cleaned up

🚀 Phase 2 conversation pipeline is fully operational!
```

### Unique Validations
- **Bidirectional Safety**: Tests both user input AND AI response filtering
- **Context Injection**: Verifies Neptune context flows into persona prompts
- **TTL Management**: Confirms 24-hour message expiration
- **Session Lifecycle**: Complete connect → process → disconnect flow

### When to Use
- 🔄 **Daily development** - comprehensive workflow validation
- 🐛 **Integration debugging** - see entire pipeline in action  
- 📋 **Feature validation** - ensure new features work end-to-end
- 🚀 **Pre-deployment** - validate business logic before infrastructure

---

## 🐳 Integration Tests - AWS Infrastructure Validation

**Purpose**: Test actual AWS services via LocalStack emulation

### What We Test
- ✅ **LocalStack Connection**: AWS service emulation connectivity
- ✅ **DynamoDB Tables**: Create, configure, and manage real tables
- ✅ **CRUD Operations**: Put, Get, Query operations with real AWS SDK
- ✅ **GSI Functionality**: Global Secondary Index queries
- ✅ **TTL Handling**: Time-to-Live attribute processing
- ✅ **AWS SDK v2**: Latest SDK integration and authentication

### How to Run
```bash
./scripts/test-integration.sh
```

### Technical Details
- **Speed**: ~30 seconds (includes Docker startup)
- **Dependencies**: Docker, LocalStack
- **Environment**: Docker-enabled machine
- **Coverage**: AWS service integration

### Prerequisites
```bash
# Docker must be running
docker info

# LocalStack will be auto-started if not running
# docker-compose up -d
```

### What You'll See
```
=== InnerWorld Integration Tests ===
Testing actual AWS services via LocalStack...

🔌 1. LOCALSTACK CONNECTION - Testing AWS service connectivity...
   ✅ LocalStack connection successful
   ✅ DynamoDB service accessible

📊 2. DYNAMODB SETUP - Creating test tables...
   ⏳ Waiting for tables to be active...
   ✅ LiveConversations table created
   ✅ UserContextCache table created

💾 3. DYNAMODB OPERATIONS - Testing real AWS SDK calls...
   ✅ Put item operation successful
   ✅ Get item operation successful  
   ✅ Query operation successful
   ✅ TTL verification successful

🧹 5. CLEANUP - Removing test tables...
   ✅ Test tables cleaned up

🚀 Infrastructure is ready for Lambda deployment!
```

### Real AWS Operations Tested
```go
// Real DynamoDB table creation with GSI
CreateTable(&dynamodb.CreateTableInput{
    TableName: "LiveConversations-test",
    GlobalSecondaryIndexes: []types.GlobalSecondaryIndex{...},
})

// Real AWS SDK v2 operations
PutItem(ctx, &dynamodb.PutItemInput{...})
GetItem(ctx, &dynamodb.GetItemInput{...})
Query(ctx, &dynamodb.QueryInput{...})
```

### When to Use
- 🚀 **Pre-deployment validation** - ensure infrastructure readiness
- 🔧 **AWS SDK updates** - verify compatibility
- 🏗️ **Infrastructure changes** - validate table schemas
- 🐛 **Production issue debugging** - replicate AWS behavior locally

---

## 📊 Test Coverage Matrix

| Component | Unit Tests | Component Tests | Integration Tests |
|-----------|:----------:|:---------------:|:-----------------:|
| **Configuration** | ✅ | ✅ | - |
| **OpenAI Embeddings** | ✅ | ✅ | - |
| **OpenRouter LLM** | ✅ | ✅ | - |
| **Type Validation** | ✅ | ✅ | - |
| **Persona Loading** | - | ✅ | - |
| **Safety System** | - | ✅ | - |
| **DynamoDB Mock** | - | ✅ | - |
| **Conversation Flow** | - | ✅ | - |
| **AWS DynamoDB** | - | - | ✅ |
| **AWS SDK v2** | - | - | ✅ |
| **Infrastructure** | - | - | ✅ |

---

## ⚡ Performance Characteristics

### Development Workflow Performance
```bash
# Daily development (95% of testing)
./scripts/test-unit.sh             # ~2s
./scripts/test-e2e-conversation.sh # ~3s
# Total: ~5 seconds, zero dependencies

# Pre-deployment (5% of testing)  
./scripts/test-integration.sh     # ~30s, requires Docker
```

### Build Performance
```bash
./scripts/build-phase2.sh
# Builds:
# - 3 Lambda functions (production)
# - 2 test executables (development)
# - 5 deployment packages (AWS ready)
```

---

## 🛠️ Development Workflows

### 🔄 **Daily Development Cycle**
```bash
# 1. Make code changes
vim internal/workflow/langchain.go

# 2. Run fast tests (5 seconds)
./scripts/test-unit.sh && ./scripts/test-e2e-conversation.sh

# 3. Build if tests pass
./scripts/build-phase2.sh
```

### 🚀 **Pre-Deployment Validation**
```bash
# 1. Run all tests
./scripts/test-unit.sh
./scripts/test-e2e-conversation.sh  
./scripts/test-integration.sh

# 2. Build deployment packages
./scripts/build-phase2.sh

# 3. Deploy to AWS (Terraform)
```

### 🐛 **Debugging Workflow**
```bash
# Component issue?
./scripts/test-unit.sh

# Business logic issue?
./scripts/test-e2e-conversation.sh

# Infrastructure issue?
./scripts/test-integration.sh
```

---

## 🏗️ Test File Structure

```
backend/
├── cmd/
│   ├── test-e2e-conversation/main.go    # Component test runner
│   └── test-integration/main.go         # Integration test runner
├── scripts/
│   ├── test-unit.sh                     # Unit test runner
│   ├── test-e2e-conversation.sh         # Component test runner
│   ├── test-integration.sh              # Integration test runner
│   └── build-phase2.sh                  # Build all components
└── internal/
    ├── config/config_test.go            # Unit tests
    ├── embeddings/openai_test.go        # Unit tests
    ├── llm/openrouter_test.go           # Unit tests
    └── types/conversation_test.go       # Unit tests
```

---

## 🎯 Testing Best Practices

### ✅ **Do's**
- **Run unit + component tests** on every code change (5 seconds)
- **Use integration tests** before deployment or infrastructure changes
- **Mock external services** for component tests (fast, reliable)
- **Test real AWS services** for infrastructure validation
- **Keep tests focused** - each test suite has a distinct purpose

### ❌ **Don'ts**
- **Don't skip unit tests** - they catch issues early
- **Don't rely only on integration tests** - they're slow and fragile
- **Don't mix testing concerns** - unit tests shouldn't need Docker
- **Don't ignore failed tests** - they prevent deployment issues
- **Don't over-test** - avoid redundant coverage

---

## 📋 Quick Reference

| Need | Run This | Time | Dependencies |
|------|----------|------|--------------|
| **Quick validation** | `./scripts/test-unit.sh` | 2s | None |
| **Full workflow test** | `./scripts/test-e2e-conversation.sh` | 3s | None |
| **Pre-deployment** | `./scripts/test-integration.sh` | 30s | Docker |
| **Build everything** | `./scripts/build-phase2.sh` | 10s | None |

---

## 🚀 Production Readiness

### ✅ **What Our Tests Validate**

**Business Logic** (Component Tests):
- Bidirectional safety filtering (input + output)
- Persona context injection with user data
- Complete conversation pipeline (6 steps)
- Session management and cleanup
- DynamoDB TTL handling (24-hour expiration)

**Infrastructure** (Integration Tests):
- Real AWS DynamoDB operations
- Table creation with GSI
- AWS SDK v2 compatibility
- LocalStack emulation accuracy

**Individual Components** (Unit Tests):
- Configuration management
- API client functionality
- Data type validation
- Component isolation

### 🎯 **Coverage Confidence**
- **100% of critical paths** tested
- **Zero redundancy** between test suites  
- **Multiple validation layers** for high-risk areas (safety, storage)
- **Real AWS service validation** via LocalStack

---

## 🔄 Continuous Integration

### GitHub Actions / CI Pipeline
```yaml
# Suggested CI configuration
- name: Unit Tests
  run: ./scripts/test-unit.sh
  
- name: Component Tests  
  run: ./scripts/test-e2e-conversation.sh
  
- name: Integration Tests
  run: ./scripts/test-integration.sh
  
- name: Build Lambdas
  run: ./scripts/build-phase2.sh
```

**Total CI Time**: ~35 seconds (all tests + build)
**Dependencies**: Docker (for integration tests only)

---

## 📚 Additional Resources

- **[Phase 2 Implementation Summary](PHASE_2_IMPLEMENTATION_SUMMARY.md)** - Complete implementation details
- **[Lambda Deployment Guide](LAMBDA_DEPLOYMENT_GUIDE.md)** - AWS deployment instructions
- **[Project README](../../backend/README.md)** - Development setup and usage

---

**Testing Strategy Owner**: Darren  
**Last Updated**: Phase 2 Implementation Complete  
**Status**: ✅ Production Ready
