# **MVP Development Checklist – InnerWorld **

---

## **Phase 1 – Foundation**

**Criteria:** Essential systems and architecture that the application cannot function without. No dependencies.

---

### **Nataly – DevOps/Infrastructure**

[ ] **Set up Terraform IaC foundation**
[ ] Initialize Terraform project with AWS provider configuration.
[ ] Create modular Terraform structure for dev/staging/prod environments.
[ ] Set up remote state backend (S3 + DynamoDB) for team collaboration.

[ ] **Configure core AWS infrastructure via Terraform**
[ ] Deploy VPC, subnets, security groups, and networking components.
[ ] Set up AWS Secrets Manager for credentials and API keys.
[ ] Configure AWS CodePipeline for build/deploy and GitHub Actions for code quality.

[ ] **Configure AWS Cognito for authentication**
[ ] Create Cognito User Pool and Identity Pool via Terraform.
[ ] Enable Apple ID and email/password sign-in.
[ ] Set up proper IAM roles and policies for Cognito integration.

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
[ ] Test rendering of placeholder assets in AR.

[ ] **Implement privacy controls**
[ ] Add FaceID/Passcode lock functionality.
[ ] Create encrypted local storage for session cache.

---

### **Darren – Backend & API**

[ ] **Create backend skeleton (FastAPI)**
[ ] Initialize FastAPI project with async support.
[ ] Create health-check endpoint for CI verification.
[ ] Set up connection to Amazon Neptune (using connection details from Terraform outputs).

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
[ ] Implement schema in Neptune dev environment using Gremlin/SPARQL.

---

### **Nataly – Infrastructure**

[ ] **Deploy backend infrastructure via Terraform**
[ ] Configure FastAPI backend deployment (ECS with Fargate or Elastic Beanstalk).
[ ] Set up Application Load Balancer and auto-scaling policies.
[ ] Deploy backend with proper IAM roles for Neptune and Cognito access.
[ ] Configure environment-specific backend deployments (dev/staging/prod).

---

### **Darren – Backend & AI Pipeline**

[ ] **Implement LLM conversation pipeline**
[ ] Create FastAPI endpoints for conversation requests.
[ ] Connect to Neptune to retrieve GraphRAG context using Gremlin queries.
[ ] Call Claude API with RAG context and return response.
[ ] Implement OpenAI embeddings for semantic search in Neptune.

---

## **Phase 3 – Interface Layer**

**Criteria:** User-facing UI and AR components. Dependent on Phase 1 foundation and partially on Phase 2 data layer.

---

### **Trevor – Frontend (iOS AR)**

[ ] **Implement Landing/Login/Signup screens**
[ ] Build SwiftUI screens for login and signup.
[ ] Integrate AWS Cognito sign-in flow (Apple ID, email/password).
[ ] Handle token exchange with backend.

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

---

### **Trevor – Chat UI**

[ ] **Build immersive chat interface**
[ ] Integrate chat UI within ImmersiveSpace environment.
[ ] Display persona avatar/emotes as 3D elements in the space.
[ ] Handle input and streaming LLM responses in immersive context.

[ ] **Implement session flow and timing**
[ ] Create 20-minute daily session timer with visible countdown.
[ ] Build session flow: micro-centering → chat → reflection → gratitude note → exit.
[ ] Add session start/end UI with simple controls.

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
[ ] Apply selected theme dynamically in ImmersiveSpace.

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
[ ] Deploy subscription infrastructure via Terraform (API Gateway, Lambda).
[ ] Configure FastAPI endpoints for subscription validation.
[ ] Integrate with App Store subscription APIs and webhook handling.

[ ] **Admin/operator tools**
[ ] Deploy admin infrastructure via Terraform (separate VPC/security context).
[ ] Create configurable persona scripts and prompts (YAML/JSON).
[ ] Build safety threshold tuning interface with proper access controls.
[ ] Add habit and resource configuration tools.

---