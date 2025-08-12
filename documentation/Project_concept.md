# Project Name
Dreamroom Personas (working title)

## Project Description
A mobile iOS AR app (13+) where teens talk with four AI personas inside a dreamlike, RealityKit-rendered square room anchored in their real environment. Each wall represents a different persona — Courage, Comfort, Creative, Compass — with its own style and interaction points. Sessions are capped at 20 minutes/day to encourage short, meaningful use and positive real-world behaviors (habit prompts, gratitude notes). Conversations are stored as a per-user GraphRAG in cloud Neo4j to allow the personas to reflect the user’s own themes and inner world without making therapy claims. Safety is handled via classifiers that surface US crisis resources when needed; no human review.

## Target Audience
- Teens 13+ seeking reflective, creative self-talk without social media distractions
- Secondary: parents/educators (understanding, but not primary users)

## Desired Features
### Core Experience
- [ ] **AR Dream Room (RealityKit)**
    - [ ] Square room anchored on user’s surface with passthrough environment
    - [ ] Four walls, each themed to its persona
    - [ ] Hotspots (bookcase, desk, window, plant) with static content
    - [ ] Simple cosmetic changes unlocked via consistent habit confirmation
- [ ] **Persona Agents**
    - [ ] Courage — bold motivator
    - [ ] Comfort — empathetic supporter
    - [ ] Creative — playful idea generator
    - [ ] Compass — values-based guide
    - [ ] One persona active per session, visible emotes, limited idle movement
    - [ ] Guardrailed prompts; reflective-play framing
- [ ] **Sessions & Time Limits**
    - [ ] 20 minutes total/day
    - [ ] Flow: micro-centering → chat → reflection → gratitude note → exit

### Memory & RAG
- [ ] **Cloud Neo4j GraphRAG**
    - [ ] Per-user graph: {Event, Feeling, Need, Value, Goal, Habit, Person, Topic}
    - [ ] Edges: temporal, causal, about, supports, conflicts, felt_during
    - [ ] Embeddings via OpenAI text-embedding-3-small
    - [ ] Retrieval via intent → subgraph expansion → Claude prompt context
    - [ ] PII redaction; user-controlled deletions
- [ ] **On-device cache**
    - [ ] Encrypted local store for recent sessions
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

### Admin/Operator Tools
- [ ] Configurable persona scripts, prompts, habits, resources (YAML/JSON)
- [ ] Safety threshold tuning

## Design Requests
- [ ] **Art Direction**
    - [ ] Pixar UP warmth, soft/unsaturated
    - [ ] glTF/USDC assets for easy swapping
- [ ] **UX**
    - [ ] Simple session start/end; visible timer
- [ ] **Accessibility**
    - [ ] Dynamic type, dyslexia-friendly font, high contrast mode

## Other Notes
- **Platform/Stack**: iOS AR app (Swift, RealityKit), cloud Neo4j Aura, LLM = Claude, embeddings = OpenAI. TestFlight for beta.
- **Freemium**: Free = 20 min/day, base theme, 30-day memory. Premium = extended limits, extra themes, 1-year memory, advanced trends.
- **Launch Locale**: US-only crisis resources at MVP.
