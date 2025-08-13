package personas

import (
	"fmt"
	"log"
	"strings"
)

// PersonaConfig defines the structure for persona configuration
type PersonaConfig struct {
	Name         string   `json:"name" yaml:"name"`
	SystemPrompt string   `json:"system_prompt" yaml:"system_prompt"`
	Boundaries   []string `json:"boundaries" yaml:"boundaries"`
	Tone         string   `json:"tone" yaml:"tone"`
	Examples     []string `json:"examples" yaml:"examples"`
	Description  string   `json:"description" yaml:"description"`
}

// PersonaLoader handles loading persona configurations
type PersonaLoader struct {
	// Phase 2: Use in-memory defaults, Phase 4+: Load from S3/DynamoDB
	personas map[string]*PersonaConfig
}

// NewPersonaLoader creates a new persona loader with default configurations
func NewPersonaLoader() *PersonaLoader {
	loader := &PersonaLoader{
		personas: make(map[string]*PersonaConfig),
	}

	// Initialize with default persona configurations
	loader.loadDefaultPersonas()

	return loader
}

// LoadPersona retrieves a persona configuration by name
func (p *PersonaLoader) LoadPersona(personaName string) (*PersonaConfig, error) {
	personaName = strings.ToLower(personaName)

	persona, exists := p.personas[personaName]
	if !exists {
		// Return default persona if specific one not found
		log.Printf("Persona '%s' not found, using default", personaName)
		return p.personas["default"], nil
	}

	log.Printf("Loaded persona: %s", persona.Name)
	return persona, nil
}

// GetAvailablePersonas returns list of available persona names
func (p *PersonaLoader) GetAvailablePersonas() []string {
	names := make([]string, 0, len(p.personas))
	for name := range p.personas {
		if name != "default" { // Exclude internal default
			names = append(names, name)
		}
	}
	return names
}

// loadDefaultPersonas initializes ONLY the default persona template
func (p *PersonaLoader) loadDefaultPersonas() {
	// Default persona for Phase 2 testing - SINGLE TEMPLATE ONLY
	p.personas["default"] = &PersonaConfig{
		Name: "Supportive Companion",
		SystemPrompt: `You are a supportive AI companion for a teen wellness app called InnerWorld. 
You are warm, encouraging, and non-judgmental. You help teens reflect on their feelings and experiences 
without giving therapy or medical advice. Keep responses concise (2-3 sentences) and age-appropriate for 13+.
Focus on validation, gentle questions, and encouraging self-reflection.`,
		Boundaries: []string{
			"No therapy or medical advice",
			"No diagnosis of mental health conditions",
			"Encourage talking to trusted adults for serious concerns",
			"Keep conversations age-appropriate for teens 13+",
			"Focus on reflection and validation, not solutions",
		},
		Tone: "warm, supportive, non-judgmental",
		Examples: []string{
			"That sounds really challenging. How are you feeling about it right now?",
			"It's completely normal to feel nervous about new situations. What's one small thing that might help?",
			"You're being really thoughtful about this. What matters most to you in this situation?",
		},
		Description: "Default supportive companion template for Phase 2 testing",
	}

	log.Printf("Loaded default persona configuration (Phase 2: template only)")
}

// FormatPersonaPrompt creates the full system prompt with user context
func (p *PersonaLoader) FormatPersonaPrompt(personaName string, userContext map[string]interface{}) (string, error) {
	persona, err := p.LoadPersona(personaName)
	if err != nil {
		return "", fmt.Errorf("failed to load persona: %w", err)
	}

	prompt := persona.SystemPrompt

	// Add context if available (Phase 2: basic context, Phase 3+: rich GraphRAG context)
	if len(userContext) > 0 {
		prompt += fmt.Sprintf("\n\nUser Context: The user has previously discussed themes around %v. "+
			"Reference this context naturally in your responses when relevant, but don't force it.",
			extractContextSummary(userContext))
	}

	// Add boundaries as a reminder
	if len(persona.Boundaries) > 0 {
		prompt += "\n\nRemember these boundaries:"
		for _, boundary := range persona.Boundaries {
			prompt += "\n- " + boundary
		}
	}

	return prompt, nil
}

// extractContextSummary creates a brief summary from user context (helper function)
func extractContextSummary(context map[string]interface{}) string {
	if themes, ok := context["recent_themes"].([]interface{}); ok {
		var themeStrings []string
		for _, theme := range themes {
			if str, ok := theme.(string); ok {
				themeStrings = append(themeStrings, str)
			}
		}
		if len(themeStrings) > 0 {
			return strings.Join(themeStrings[:min(3, len(themeStrings))], ", ")
		}
	}
	return "various personal topics"
}

// Helper function for min
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
