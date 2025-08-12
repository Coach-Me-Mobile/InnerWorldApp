Questions to clarify

Age range & compliance: Strictly 13–17, or include <13? (Determines COPPA, parental consent flows, data retention.)

Strictly 13+.

Platform first: Mobile web, desktop web, or native app? (Your earlier projects used Next.js/Firebase—do you want to lean on that stack?)

Mobile application with Swift, published on Testflight for beta testing.

Visual scope: 2D isometric/side-scroll (“cozy room”) vs lightweight 3D/WebGL. Do you want Unity WebGL, Three.js, or a 2D engine like PixiJS?

3D reality-kit swift engine for room visualization, VR.

Persona roster: How many archetypes at MVP (e.g., Motivator, Comforter, Empath, Creative, Courage)? Pre-defined only, or can teens create/customize personas from templates?

4, one for each direction of the room (which will be square). Pre-defined only. 

Memory model: Should agents remember context across sessions? If yes, how long and how private? (Per-persona journals vs global memory.)

We want conversations to be stored as a GraphRAG infrastructure with neo4j that allows the personas to implement RAG when talking to users. This will not be a global graph, but a per-user graph. We are still debating the best ways to manage and store this information (e.g. cloud or on user phones, and if so, what are pros and cons).

Time limits: What’s the daily cap (e.g., 10–15 min/day)? Cooldown rules?

20 minutes per day.

Off-app nudges: What kinds of “IRL actions” do you want (micro-quests, habit prompts, gratitude notes)? How do we confirm completion without surveillance?

Habit prompts and graittude notes. E.g. encourage them to “go have a conversation with their parent” or something like that when appropriate. Micro-quests are a bit out of scope. We don’t need to confirm completion beyond a trust “yes” or “no” response from the user themselves when asked, including a small reflection about it.

Safety rails: Escalation for self-harm signals, bullying, or crisis content—what jurisdiction(s) and standard (e.g., WHO guidelines)? Any “human review” plan?

No human review, but we shoud be able to detect for signals and have a pop up with resources (text based or call based hotlines). Give recommendations on best practice, as we don’t want to be responsible for giving them any advice regarding this. 

Tone & boundaries: Agents must avoid therapy claims and medical advice—OK to position as journaling/reflective play?

Yes, perfect to position as journaling/reflective play.

Integrations: Pinterest boards, Spotify playlists, Google Drive for moodboard images, or none at MVP?

None at MVP.

Monetization (later): Free pilot? Grant-funded? Parent subscription? (Impacts data policy and feature gating.)

Freemium.

Art direction: “Dreamlike, cozy, simple changes” — any reference palettes or games (e.g., Alba, Monument Valley, Stardew’s color softness)? Accessibility contrast targets?

Bitlife for concept (NOT ART), Pixar UP movie style, soft, unsaturated. We have not yep pin-pointed a particular style, we want to be able to switch out our 3D models at will as we are still planning the design.





Follow-ups / decisions to lock

Device target for “VR”: iPhone (AR-style room on camera background), iPad, or visionOS headset? RealityKit can do immersive on visionOS; iOS is AR-first. Which is MVP?

No visionOS headset. It’s all finger/draged based, where a user is anchored to the center point of the room, and can click on/select an entity and then be zoomed into it (camera animation/viewpoint goes into the entity view, when they go back gets zoomed out into the room centerpoint view).

Cloud vs on-device graph: Start with cloud Neo4j (e.g., Aura) per user or attempt a local graph (e.g., property-graph emulation over SQLite) with periodic encrypted sync? My rec: cloud to ship faster, add offline cache later.

Let’s go with your cloud-based suggestion.

LLM provider + embedding model: Any preference (OpenAI, Anthropic, Gemini)? We’ll need both chat + embeddings. Under-18 usage terms vary by provider.

OpenAI, specifically OpenRouter using OpenAI SDK. Reminder, we need to support at least a hundred concurrent users (and be open to supporting additional architecture as the user base grows), so that’s a consideration during our implementation structure. 

Persona names & traits: You want 4 personas (one per room wall). Shall I draft names/voices? (e.g., Courage, Comfort, Creative, Compass (values/ethics).)

Sure, draft some names.

Freemium gating: What’s free vs paid at MVP (e.g., #sessions/day beyond 20 minutes cap, extra room themes, historical mood trends)?

Pay for environment personalization for now. For MVP, we don’t need payment, we just need to ensure our architecture can be ammenable to this at some future point.

Crisis resources locale: US-only at launch, or include CA/UK? (Defines hotline list and wording.)

Global. 

Legal copy: OK to include a short “not therapy” disclaimer on onboarding + settings?

Yep. Disclaimers everywhere! MUST PHYSICALLY MARK CHECKBOX THAT THEY UNDERSTAND THAT WE ARE NOT THERPAY AND THEY CANNOT SUE USSSS