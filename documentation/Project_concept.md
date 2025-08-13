# Project Name
InnerWorld (formerly Dreamroom Personas)

## Project Description
A mobile iOS VR app (13+) where teens talk with four AI personas inside a dreamlike, RealityKit-rendered square room anchored in their real environment. Each wall represents a different persona — Courage, Comfort, Creative, Compass — with its own style and interaction points. Sessions are capped at 20 minutes/day to encourage short, meaningful use and positive real-world behaviors (habit prompts, gratitude notes). Conversations are stored as a per-user GraphRAG in AWS Neptune to allow the personas to reflect the user's own themes and inner world without making therapy claims. Real-time conversations use WebSocket API with AWS Lambda functions for serverless processing. Safety is handled via classifiers that surface US crisis resources when needed; no human review.

## Target Audience
- Teens 13+ seeking reflective, creative self-talk without social media distractions
- Secondary: parents/educators (understanding, but not primary users)

## Desired Features
### Core Experience
- [ ] **VR Dream Room (RealityKit)**
    - [ ] Square room anchored on user's surface with passthrough environment (ImmersiveSpace)
    - [ ] Four walls, each themed to its persona
    - [ ] Hotspots (bookcase, desk, window, plant) with static content
    - [ ] Simple cosmetic changes unlocked via consistent habit confirmation
    - [ ] USDZ format assets for RealityKit compatibility
- [ ] **Persona Agents**
    - [ ] Courage — bold motivator
    - [ ] Comfort — empathetic supporter
    - [ ] Creative — playful idea generator
    - [ ] Compass — values-based guide
    - [ ] One persona active per session, visible emotes, limited idle movement
    - [ ] Guardrailed prompts; reflective-play framing
- [ ] **Sessions & Time Limits**
    - [ ] 20 minutes total/day
    - [ ] Flow: WebSocket connect → micro-centering → chat → reflection → gratitude note → WebSocket disconnect
    - [ ] Real-time WebSocket communication with AWS Lambda backend

### Memory & RAG
- [ ] **AWS Neptune GraphRAG**
    - [ ] Per-user graph: {Event, Feeling, Need, Value, Goal, Habit, Person, Topic}
    - [ ] Edges: temporal, causal, about, supports, conflicts, felt_during
    - [ ] Embeddings via OpenAI text-embedding-3-small
    - [ ] Retrieval via intent → subgraph expansion → Claude prompt context
    - [ ] PII redaction; user-controlled deletions
    - [ ] Gremlin/SPARQL query interface for graph traversals
- [ ] **Live Conversation Storage**
    - [ ] DynamoDB table for real-time conversation storage with TTL
    - [ ] Session-based processing: DynamoDB → Neptune graph update
- [ ] **On-device cache**
    - [ ] Encrypted local store for recent sessions and Neptune context cache
    - [ ] Future: offline mode with sync

### Safety & Privacy
- [ ] **Safety Guardrails**
    - [ ] On-device + server moderation models for self-harm/abuse/bullying
    - [ ] US crisis modal (988, Trevor Project, Crisis Text Line)
    - [ ] Journaling-only mode after trigger
- [ ] **Compliance**
    - [ ] 13+ gate; “not therapy” disclaimer
    - [ ] US privacy policy; data minimization; no ad SDKs
- [ ] **Privacy Controls**
    - [ ] FaceID/Passcode lock
    - [ ] Per-persona memory toggle; 30-day retention for free users

### Content & Personalization
- [ ] **Persona Cards** — name, vibe, boundaries, 3 starter prompts
- [ ] **Room Themes** — 1 base (free), more in premium
- [ ] **Hotspot Content** — static tiles (quotes, breathing, blank journal)

### Analytics (Privacy-Preserving)
- [ ] Local by default, opt-in cloud
- [ ] Track session count, persona chosen, mood deltas, habit confirmations

### Technical Implementation
- [ ] **WebSocket Real-time Communication**
    - [ ] Lambda functions: $connect, $disconnect, $default, sendmessage
    - [ ] LangGraph workflow: safety_check → persona_prompt → llm_generation → live_storage
    - [ ] Connection state management and automatic reconnection
- [ ] **Optimized Context Handling**
    - [ ] Login-time Neptune context retrieval and caching (DynamoDB/ElastiCache)
    - [ ] Session-based processing: real-time DynamoDB → post-session Neptune update
    - [ ] Cached context for fast conversation responses
- [ ] **Infrastructure as Code**
    - [ ] Terraform modules for VPC, networking, security groups
    - [ ] Environment-specific deployments (dev/staging/prod)
    - [ ] AWS CodePipeline for CI/CD + GitHub Actions for code quality

### Admin/Operator Tools
- [ ] Configurable persona scripts, prompts, habits, resources (YAML/JSON)
- [ ] Safety threshold tuning

## Design Requests
- [ ] **Art Direction**
    - [ ] Pixar UP warmth, soft/unsaturated
    - [ ] USDZ assets for RealityKit compatibility and easy swapping
- [ ] **UX**
    - [ ] Simple session start/end; visible timer
    - [ ] WebSocket connection status indicators (connecting, connected, disconnected, error)
    - [ ] Real-time message delivery confirmation and typing indicators
- [ ] **Accessibility**
    - [ ] Dynamic type, dyslexia-friendly font, high contrast mode

## Other Notes
- **Platform/Stack**: iOS VR app (Swift, RealityKit), AWS Neptune + DynamoDB, WebSocket API + Lambda functions, LLM = Claude via OpenRouter, embeddings = OpenAI. AWS Cognito for auth (Apple ID + email/password). TestFlight for beta.
- **Architecture**: Serverless backend with AWS Lambda, WebSocket API Gateway for real-time communication, Neptune for GraphRAG storage, DynamoDB for live conversation cache, S3 for assets, Secrets Manager for credentials.
- **Freemium**: Free = 20 min/day, base theme, 30-day memory. Premium = extended limits, extra themes, 1-year memory, advanced trends.
- **Launch Locale**: US-only crisis resources at MVP.
