# **MVP Development Checklist – InnerWorld **

---

## **Phase 1 – Foundation**

**Criteria:** Essential systems and architecture that the application cannot function without. No dependencies.

---

### **Nataly – DevOps/Infrastructure**

[x] **Set up Terraform IaC foundation**
[x] Initialize Terraform project with AWS provider configuration.
[x] Create modular Terraform structure for dev/staging/prod environments.
[x] Set up remote state backend (S3 + DynamoDB) for team collaboration.

[x] **Configure core AWS infrastructure via Terraform**
[x] Deploy VPC, subnets, security groups, and networking components.
[x] Set up AWS Secrets Manager for credentials and API keys.
[x] Configure AWS CodePipeline for build/deploy and GitHub Actions for code quality.

[x] **Configure AWS Cognito for authentication**
[x] Create Cognito User Pool and Identity Pool via Terraform.
[x] Enable Apple ID and email/password sign-in.
[x] Set up proper IAM roles and policies for Cognito integration.

---

### **Hutch – 3D Assets & Graph Database**

[ ] **Define 3D asset standards**
[ ] Standardize on USDZ format for RealityKit compatibility.
[ ] Define scaling, lighting, and material requirements for ImmersiveSpace.
[ ] Document asset optimization guidelines for VR performance.

[ ] **Model base Dreamroom environment**
[ ] Create square room with 4 themed walls as USDZ assets.
[ ] Design for ImmersiveSpace (360-degree immersive environment).
[ ] Validate rendering performance and visual quality in RealityKit.

[ ] **Prepare for Neptune integration**
[ ] Define GraphRAG data model and schema requirements.
[ ] Document Neptune connection patterns for backend services.

---

### **Trevor – Frontend (iOS VR)**

[ ] **Set up Swift/RealityKit project scaffold**
[ ] Create base iOS app project in Xcode.
[ ] Integrate RealityKit scene rendering.
[ ] Test rendering of placeholder assets in VR.

[ ] **Implement privacy controls**
[ ] Add FaceID/Passcode lock functionality.
[ ] Create encrypted local storage for session cache.

---

### **Darren – Backend & API**

[X] **Create serverless backend (AWS Lambda)**
[X] Initialize Lambda functions for conversation handling.
[X] Create health-check Lambda for monitoring.
[X] Set up Neptune connection layer for Lambda functions.

[X] **Configure external API integrations**
[X] Set up OpenRouter API client for LLM conversations (Claude, GPT, etc.).
[X] Configure OpenAI API for text embeddings.

---

## **Phase 2 – Data Layer**

**Criteria:** Data storage, retrieval, and management. Dependent on Phase 1 foundation.

---

### **Hutch – Graph Database**

[ ] **Design GraphRAG schema**
[ ] Define nodes: Event, Feeling, Need, Value, Goal, Habit, Person, Topic.
[ ] Define edge types: temporal, causal, about, supports, conflicts, felt_during.
[ ] Implement schema in Neptune dev environment using Gremlin/SPARQL.

---

### **Nataly – Infrastructure**

[ ] **Deploy serverless backend infrastructure via Terraform**
[ ] Configure WebSocket API with Lambda functions for real-time conversation.
[ ] Set up DynamoDB table for live conversation storage with TTL.
[ ] Set up Lambda layers for shared dependencies (OpenRouter, Neptune, LangGraph clients).
[ ] Deploy Lambda functions with proper IAM roles for Neptune, DynamoDB, and Cognito access.
[ ] Configure environment-specific deployments (dev/staging/prod).

---

### **Darren – Backend & AI Pipeline**

[ ] **Implement real-time conversation pipeline with WebSocket + LangGraph**
[ ] Create WebSocket Lambda functions: $connect, $disconnect, $default, sendmessage.
[ ] Build LangGraph workflow: safety_check → persona_prompt → llm_generation → live_storage.
[ ] Implement login context caching: Neptune context retrieval on authentication and cache in session store.
[ ] Create real-time message handling: retrieve cached context → LangGraph processing → WebSocket response.
[ ] Build session end processing: DynamoDB → Neptune graph update → refresh cached context.
[ ] Call OpenRouter API (Claude/GPT models) through LangGraph generation node.
[ ] Add conversation state persistence and persona-specific prompt templates.

---

## **Phase 3 – Interface Layer**

**Criteria:** User-facing UI and VR components. Dependent on Phase 1 foundation and partially on Phase 2 data layer.

---

### **Trevor – Frontend (iOS VR)**

[ ] **Implement Landing/Login/Signup screens**
[ ] Build SwiftUI screens for login and signup.
[ ] Integrate AWS Cognito sign-in flow (Apple ID, email/password).
[ ] Handle token exchange with backend.
[ ] Trigger Neptune context caching on successful login.
[ ] Cache user context locally for offline scenarios.

[ ] **Render ImmersiveSpace Dreamroom**
[ ] Load base Dreamroom USDZ assets into ImmersiveSpace.
[ ] Create 360-degree immersive environment with 4 themed walls.
[ ] Implement hotspot interactions within immersive context (gaze/tap detection).

---

### **Hutch + Trevor Collaboration**

[ ] **Integrate themed wall art & textures**
[ ] Create USDZ wall textures for Courage, Comfort, Creative, Compass.
[ ] Implement dynamic theme loading into ImmersiveSpace environment.

---

### **Hutch + Nataly Collaboration**

[ ] **Deploy Neptune infrastructure via Terraform**
[ ] Create Neptune cluster configuration in Terraform modules.
[ ] Set up Neptune-specific VPC endpoints and security groups.
[ ] Configure Neptune parameter groups for optimal GraphRAG performance.
[ ] Deploy dev and prod Neptune clusters with proper IAM roles.

---

## **Phase 4 – Implementation Layer**

**Criteria:** Functional core features delivering app value. Dependent on all prior phases.

---

### **Darren – AI Conversation**

[ ] **Enable persona-based conversation**
[ ] Configure persona selection per session.
[ ] Pass persona-specific prompt templates to LLM.
[ ] Add basic emotion-tagging for emotes.

#### DynamoDB Table: LiveConversations
{
    "conversation_id": "session_123_2024-01-15",  # Partition Key
    "message_id": "msg_001",                      # Sort Key
    "user_id": "user123",
    "persona": "courage",
    "timestamp": "2024-01-15T10:05:00Z",
    "message_type": "user" | "assistant",
    "content": "I'm nervous about my presentation",
    "session_start": "2024-01-15T10:00:00Z",
    "ttl": 1705334400,  # Auto-delete after processing
    # GSI for session queries
    "session_id": "session_123",
    "message_sequence": 1
}

#### Optimized Conversation Flow
```
User Login:
Authenticate with Cognito
Neptune Context Retrieval - get user's full conversation history/context
Cache context in user session (DynamoDB/ElastiCache)
Context available for all conversations during login session

Conversation Session Start:
Connect to WebSocket - establish persistent connection
Retrieve cached context from login session
Prime LangGraph - load persona + cached user context
Begin conversation - real-time message exchange via WebSocket

During Conversation:
Message received via WebSocket
Store in DynamoDB - immediate persistence with conversation_id
LangGraph processing - with pre-cached Neptune context
OpenRouter LLM call - generate persona response
Response via WebSocket - immediate delivery to VR app
Update DynamoDB - store AI response

Session End (20 minutes or manual):
Trigger session processing Lambda
Retrieve full conversation from DynamoDB
Extract conversation elements (Events, Feelings, Values, etc.)
Update Neptune graph - create nodes and relationships
Update cached context for next conversation
Clean up DynamoDB - remove processed conversation data
```

#### Backend LangGraph Implementation Examples

##### Optimized LangGraph Workflow
```python
def create_conversation_graph():
    """Simplified workflow - context already cached from login"""
    graph = StateGraph()
    
    # Per-message processing (context pre-loaded)
    graph.add_node("safety_check", safety_moderation_node)
    graph.add_node("persona_prompt", persona_prompt_node)
    graph.add_node("llm_generation", openrouter_generation_node)
    graph.add_node("live_storage", dynamodb_storage_node)
    
    # Define edges
    graph.add_edge("safety_check", "persona_prompt")
    graph.add_edge("persona_prompt", "llm_generation") 
    graph.add_edge("llm_generation", "live_storage")
    
    return graph.compile()

def create_login_context_handler():
    """Separate handler for login-time context retrieval"""
    graph = StateGraph()
    
    graph.add_node("neptune_context_retrieval", neptune_full_context_node)
    graph.add_node("context_caching", cache_context_node)
    
    return graph.compile()
```

##### Login Context Handler
```python
def login_context_handler(event, context):
    """Called during user authentication to cache Neptune context"""
    user_id = event['user_id']
    
    # 1. Retrieve full GraphRAG context from Neptune
    full_context = get_user_context_graph(user_id)
    
    # 2. Cache context for login session (ElastiCache or DynamoDB)
    cache_user_context(user_id, full_context, ttl=3600)  # 1 hour TTL
    
    return {"statusCode": 200, "cached_context": True}

##### Optimized WebSocket Handler
```python
def conversation_handler(event, context):
    user_input = event['message']
    persona = event['persona']
    user_id = event['user_id']
    session_id = event['session_id']
    
    # 1. Retrieve cached context from login (fast!)
    cached_context = get_cached_context(user_id)
    if not cached_context:
        return {"statusCode": 401, "error": "Context not found - please re-login"}
    
    # 2. LangGraph orchestration (no Neptune call needed)
    graph = create_conversation_graph()
    result = graph.invoke({
        "user_input": user_input,
        "persona": persona,
        "context": cached_context,
        "session_id": session_id
    })
    
    # 3. Store conversation in DynamoDB
    store_conversation_dynamodb(session_id, user_input, result.response)
    
    # 4. Send response via WebSocket
    send_websocket_message(event['connectionId'], result.response)
    
    return {"statusCode": 200}
```

##### Session Processing Lambda
```python
def session_end_processor(event, context):
    session_id = event['session_id']
    user_id = event['user_id']
    
    # 1. Retrieve full conversation from DynamoDB
    conversation = get_full_conversation(session_id)
    
    # 2. Extract conversation elements
    elements = extract_conversation_elements(conversation)
    
    # 3. Update Neptune graph
    update_neptune_graph(user_id, elements)
    
    # 4. Update cached context with new information
    refresh_cached_context(user_id, elements)
    
    # 5. Clean up DynamoDB
    cleanup_session_data(session_id)
    
    return {"statusCode": 200}

def extract_conversation_elements(conversation):
    """Extract Events, Feelings, Values, etc. from conversation"""
    elements = {
        "events": [],
        "feelings": [],
        "values": [],
        "goals": [],
        "habits": []
    }
    
    # Use LLM to analyze conversation and extract elements
    analysis_prompt = build_extraction_prompt(conversation)
    response = openrouter_client.chat.completions.create(
        model="anthropic/claude-3.5-sonnet",
        messages=[{"role": "user", "content": analysis_prompt}]
    )
    
    return parse_extracted_elements(response.choices[0].message.content)
```

[Reference Doc](https://docs.aws.amazon.com/apigateway/latest/developerguide/websocket-api-chat-app.html) 

---

### **Trevor – Chat UI**

[ ] **Build immersive WebSocket chat interface**
[ ] Integrate WebSocket connection management within ImmersiveSpace environment.
[ ] Implement real-time message handling with connection state management.
[ ] Display persona avatar/emotes as 3D elements with live response animations.
[ ] Handle WebSocket message queuing and delivery confirmation.
[ ] Add connection status indicators (connecting, connected, disconnected, error).
[ ] Implement automatic reconnection logic for dropped connections.

[ ] **Implement WebSocket session flow and timing**
[ ] Create 20-minute daily session timer with visible countdown and WebSocket session management.
[ ] Build session flow: WebSocket connect → micro-centering → chat → reflection → gratitude note → WebSocket disconnect.
[ ] Add session start/end UI with WebSocket connection status and controls.
[ ] Implement session recovery logic for network interruptions.
[ ] Handle graceful session termination with proper WebSocket cleanup.

#### WebSocket Implementation Examples

##### Connection Management
```swift
class ConversationWebSocket: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var messages: [ConversationMessage] = []
    
    func connect(sessionId: String, persona: String) {
        let url = URL(string: "wss://your-api.amazonaws.com/production")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Send initial connection with session context
        sendConnectionMessage(sessionId: sessionId, persona: persona)
        startListening()
    }
    
    private func startListening() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.startListening() // Continue listening
            case .failure(let error):
                print("WebSocket error: \(error)")
                self?.connectionState = .error
            }
        }
    }
}
```

##### Message Protocol
```swift
// Outgoing message format
struct OutgoingMessage: Codable {
    let action: String = "sendmessage"
    let message: String
    let persona: String
    let sessionId: String
    let userId: String
    let timestamp: String
}

// Incoming message handling
func handleIncomingMessage(_ data: Data) {
    if let response = try? JSONDecoder().decode(IncomingMessage.self, from: data) {
        DispatchQueue.main.async {
            self.messages.append(ConversationMessage(
                content: response.content,
                sender: .assistant,
                timestamp: Date(),
                deliveryState: .delivered,
                persona: Persona(rawValue: response.persona)
            ))
        }
    }
}
```

##### Session Management
```swift
struct ConversationSessionView: View {
    @StateObject private var webSocket = ConversationWebSocket()
    @State private var sessionTimeRemaining: TimeInterval = 1200 // 20 minutes
    @State private var currentPersona: Persona = .courage
    
    var body: some View {
        VStack {
            ConnectionStatusBar(state: webSocket.connectionState)
            SessionTimerView(timeRemaining: sessionTimeRemaining)
            ChatMessagesView(messages: webSocket.messages)
            MessageInputView { message in
                webSocket.sendMessage(message, persona: currentPersona)
            }
        }
        .onAppear { startSession() }
        .onDisappear { endSession() }
    }
    
    private func startSession() {
        let sessionId = UUID().uuidString
        webSocket.connect(sessionId: sessionId, persona: currentPersona.rawValue)
        startSessionTimer()
    }
    
    private func endSession() {
        webSocket.disconnect()
        // Trigger session processing on backend
    }
}
```

##### Connection Status UI
```swift
struct ConnectionStatusBar: View {
    let state: ConnectionState
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected, .error: return .red
        }
    }
}
```

##### Typing Indicators
```swift
struct TypingIndicatorView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
            Text("Courage is thinking...")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
```

##### Message State Management
```swift
struct ConversationMessage: Identifiable {
    let id = UUID()
    let content: String
    let sender: MessageSender
    let timestamp: Date
    var deliveryState: DeliveryState = .sending
    var persona: Persona?
}

enum DeliveryState {
    case sending
    case delivered
    case failed
    case processing // When AI is thinking
}

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case error
}
```

---

### **Hutch– Graph Memory Integration**

[ ] **Connect conversation logs to GraphRAG**
[ ] Create nodes from conversation: Event, Feeling, Value, etc.
[ ] Link nodes with edge relationships using Gremlin traversals.
[ ] Store timestamps for temporal edges in Neptune.

---

### **Trevor + Darren Collaboration**

[ ] **Implement Hotspot Features**
[ ] Bookshelf: Display static quotes/breathing exercises.
[ ] Desk: View/Add/Delete notes, store in Neptune.
[ ] Window: Display gratitude prompts and habit confirmations.
[ ] Plant: Show session timer and daily progress.

---

### **Darren – Safety**

[ ] **Add moderation & safety triggers**
[ ] Integrate on-device and backend moderation for harmful content.
[ ] Trigger US crisis modal (988, Trevor Project, Crisis Text Line) when thresholds met.
[ ] Enable journaling-only mode after safety trigger.
[ ] Add 13+ age gate and "not therapy" disclaimers.

---

## **Phase 5 – Personalization & Premium**

**Criteria:** Optional enhancements after MVP core is functional.

---

### **Hutch**

[ ] **Create additional 3D room themes**
[ ] Design premium themes and export assets.

---

### **Trevor**

[ ] **Theme switching UI**
[ ] Build settings menu to switch room themes.
[ ] Apply selected theme dynamically in ImmersiveSpace.

---

### **Nataly**

[ ] **Subscription/paywall setup**
[ ] Deploy subscription Lambda functions via Terraform (API Gateway integration).
[ ] Create Lambda functions for subscription validation and webhook handling.
[ ] Integrate with App Store subscription APIs.

[ ] **Admin/operator tools**
[ ] Deploy admin infrastructure via Terraform (separate VPC/security context).
[ ] Create configurable persona scripts and prompts (YAML/JSON).
[ ] Build safety threshold tuning interface with proper access controls.
[ ] Add habit and resource configuration tools.

---