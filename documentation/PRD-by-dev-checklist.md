# **MVP Development Checklist – InnerWorld **

---

## **Phase 1 – Foundation**

**Criteria:** Essential systems and architecture that the application cannot function without. No dependencies.

---

### **Nataly – DevOps/Infrastructure**

[ ] **Set up core AWS infrastructure**
[ ] Create AWS dev/prod accounts and environments.
[ ] Configure AWS Secrets Manager for credentials and API keys.
[ ] Set up GitHub Actions for CI/CD.

[ ] **Configure AWS Cognito for authentication**
[ ] Create Cognito User Pool and Identity Pool.
[ ] Enable Apple ID and email/password sign-in.

---

### **Hutch – 3D Assets & Graph Database**

[ ] **Define 3D asset standards**
[ ] Choose and document supported formats (glTF/USDC).
[ ] Define scaling, anchor, and lighting requirements for AR scene.

[ ] **Model base Dreamroom environment**
[ ] Create square room with 4 themed walls.
[ ] Export as RealityKit-compatible asset.
[ ] Validate anchor placement on flat surfaces in RealityKit.

[ ] **Set up Neo4j Aura cloud instance**
[ ] Create dev and prod graph databases.
[ ] Configure secure connections from backend services.

---

### **Trevor – Frontend (iOS AR)**

[ ] **Set up Swift/RealityKit project scaffold**
[ ] Create base iOS app project in Xcode.
[ ] Integrate RealityKit scene rendering.
[ ] Test rendering of placeholder assets in AR.

[ ] **Implement privacy controls**
[ ] Add FaceID/Passcode lock functionality.
[ ] Create encrypted local storage for session cache.

---

### **Darren – Backend & API**

[ ] **Create backend skeleton (FastAPI)**
[ ] Initialize FastAPI project with async support.
[ ] Create health-check endpoint for CI verification.
[ ] Set up connection to Neo4j (stub).

[ ] **Configure external API integrations**
[ ] Set up Claude API client for LLM conversations.
[ ] Configure OpenAI API for text embeddings.

---

## **Phase 2 – Data Layer**

**Criteria:** Data storage, retrieval, and management. Dependent on Phase 1 foundation.

---

### **Hutch – Graph Database**

[ ] **Design GraphRAG schema**
[ ] Define nodes: Event, Feeling, Need, Value, Goal, Habit, Person, Topic.
[ ] Define edge types: temporal, causal, about, supports, conflicts, felt_during.
[ ] Implement schema in Neo4j dev environment.

---

### **Nataly – Infrastructure**

[ ] **Deploy backend to AWS**
[ ] Configure FastAPI backend on AWS (Elastic Beanstalk or ECS).
[ ] Integrate Cognito JWT verification middleware.
[ ] Connect backend to Neo4j dev database.

---

### **Darren – Backend & AI Pipeline**

[ ] **Implement LLM conversation pipeline**
[ ] Create FastAPI endpoints for conversation requests.
[ ] Connect to Neo4j to retrieve GraphRAG context.
[ ] Call Claude API with RAG context and return response.
[ ] Implement OpenAI embeddings for semantic search.

---

## **Phase 3 – Interface Layer**

**Criteria:** User-facing UI and AR components. Dependent on Phase 1 foundation and partially on Phase 2 data layer.

---

### **Trevor – Frontend (iOS AR)**

[ ] **Implement Landing/Login/Signup screens**
[ ] Build SwiftUI screens for login and signup.
[ ] Integrate AWS Cognito sign-in flow (Apple ID, email/password).
[ ] Handle token exchange with backend.

[ ] **Render static Main Room scene**
[ ] Load base Dreamroom asset from Hutch.
[ ] Place 4 themed walls with hotspots for navigation.
[ ] Implement basic hotspot interactions (tap detection, visual highlight).

---

### **Hutch + Trevor Collaboration**

[ ] **Integrate themed wall art & textures**
[ ] Create wall textures for Courage, Comfort, Creative, Compass.
[ ] Implement theme loading into RealityKit scene.

---

## **Phase 4 – Implementation Layer**

**Criteria:** Functional core features delivering app value. Dependent on all prior phases.

---

### **Darren – AI Conversation**

[ ] **Enable persona-based conversation**
[ ] Configure persona selection per session.
[ ] Pass persona-specific prompt templates to LLM.
[ ] Add basic emotion-tagging for emotes.

---

### **Trevor – Chat UI**

[ ] **Build AR chat interface**
[ ] Overlay text chat UI in AR scene.
[ ] Display persona avatar/emotes.
[ ] Handle input and streaming LLM responses.

[ ] **Implement session flow and timing**
[ ] Create 20-minute daily session timer with visible countdown.
[ ] Build session flow: micro-centering → chat → reflection → gratitude note → exit.
[ ] Add session start/end UI with simple controls.

---

### **Hutch– Graph Memory Integration**

[ ] **Connect conversation logs to GraphRAG**
[ ] Create nodes from conversation: Event, Feeling, Value, etc.
[ ] Link nodes with edge relationships.
[ ] Store timestamps for temporal edges.

---

### **Trevor + Darren Collaboration**

[ ] **Implement Hotspot Features**
[ ] Bookshelf: Display static quotes/breathing exercises.
[ ] Desk: View/Add/Delete notes, store in Neo4j.
[ ] Window: Display gratitude prompts and habit confirmations.
[ ] Plant: Show session timer and daily progress.

---

### **Darren – Safety**

[ ] **Add moderation & safety triggers**
[ ] Integrate on-device and backend moderation for harmful content.
[ ] Trigger US crisis modal (988, Trevor Project, Crisis Text Line) when thresholds met.
[ ] Enable journaling-only mode after safety trigger.
[ ] Add 13+ age gate and "not therapy" disclaimer.

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
[ ] Apply selected theme in AR scene.

---

### **Darren**

[ ] **Persona memory toggle**
[ ] Allow users to disable per-persona memory tracking.
[ ] Adjust GraphRAG queries accordingly.

[ ] **Privacy-preserving analytics**
[ ] Implement local analytics by default with opt-in cloud sync.
[ ] Track session count, persona usage, mood deltas, habit confirmations.

---

### **Nataly**

[ ] **Subscription/paywall setup**
[ ] Configure FastAPI endpoints for subscription validation.
[ ] Integrate with App Store subscription APIs.

[ ] **Admin/operator tools**
[ ] Create configurable persona scripts and prompts (YAML/JSON).
[ ] Build safety threshold tuning interface.
[ ] Add habit and resource configuration tools.

---