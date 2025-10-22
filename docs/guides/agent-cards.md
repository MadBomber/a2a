# Creating Agent Cards

Agent Cards are the foundation of A2A agent discovery. They describe an agent's capabilities, skills, and how to interact with it.

## What is an Agent Card?

An Agent Card is a JSON document typically served at `/.well-known/agent.json` that contains:

- Agent metadata (name, version, description)
- Communication endpoint URL
- Capabilities (streaming, push notifications)
- Skills the agent can perform
- Provider information
- Authentication requirements

## Basic Agent Card

```ruby
require 'a2a'

agent_card = A2A::Models::AgentCard.new(
  name: "My Agent",
  url: "https://myagent.example.com/a2a",
  version: "1.0.0",
  description: "A helpful AI agent",
  capabilities: {
    streaming: false,
    push_notifications: false,
    state_transition_history: false
  },
  skills: [
    {
      id: "skill-1",
      name: "Question Answering",
      description: "Answer questions about various topics"
    }
  ]
)
```

## Required Fields

### name
The human-readable name of your agent:

```ruby
name: "Translation Agent"
```

### url
The HTTP(S) endpoint where the agent accepts A2A requests:

```ruby
url: "https://translate.example.com/a2a"
```

### version
Semantic version of the agent:

```ruby
version: "2.1.0"
```

### capabilities
Agent capabilities configuration:

```ruby
capabilities: {
  streaming: true,              # Supports Server-Sent Events
  push_notifications: true,     # Supports webhook callbacks
  state_transition_history: false  # Returns full state history
}
```

### skills
Array of skills the agent can perform:

```ruby
skills: [
  {
    id: "translate",
    name: "Translation",
    description: "Translate text between languages",
    tags: ["translation", "i18n", "localization"],
    examples: [
      "Translate 'hello' to Spanish",
      "Convert this text to French"
    ],
    input_modes: ["text"],
    output_modes: ["text", "data"]
  }
]
```

## Optional Fields

### description
Detailed description of the agent:

```ruby
description: "Translates text between 100+ languages using state-of-the-art neural networks"
```

### provider
Information about the organization providing the agent:

```ruby
provider: {
  organization: "Acme Translation Corp",
  url: "https://acmetranslation.com"
}
```

### authentication
Authentication schemes supported:

```ruby
authentication: {
  schemes: ["bearer", "api_key"],
  credentials: "Contact support@example.com for API keys"
}
```

### default_input_modes
Default input modalities:

```ruby
default_input_modes: ["text", "file"]
```

### default_output_modes
Default output modalities:

```ruby
default_output_modes: ["text", "data", "file"]
```

## Serving Agent Cards

### With Sinatra

```ruby
require 'sinatra'
require 'a2a'
require 'json'

# Serve agent card at well-known URL
get '/.well-known/agent.json' do
  content_type :json

  agent = A2A::Models::AgentCard.new(
    name: "My Agent",
    url: "https://#{request.host}/a2a",
    version: "1.0.0",
    capabilities: { streaming: false },
    skills: [{ id: "test", name: "Test" }]
  )

  JSON.generate(agent.to_h)
end
```

### With Rails

```ruby
# config/routes.rb
get '/.well-known/agent.json', to: 'agent#card'

# app/controllers/agent_controller.rb
class AgentController < ApplicationController
  def card
    agent = A2A::Models::AgentCard.new(
      name: "My Agent",
      url: "https://#{request.host}/a2a",
      version: "1.0.0",
      capabilities: { streaming: false },
      skills: [{ id: "test", name: "Test" }]
    )

    render json: agent.to_h
  end
end
```

## Defining Skills

Skills describe what your agent can do:

```ruby
skills: [
  {
    id: "sentiment-analysis",
    name: "Sentiment Analysis",
    description: "Analyze the emotional tone of text",
    tags: ["nlp", "sentiment", "analysis"],
    examples: [
      "What's the sentiment of: 'I love this!'",
      "Analyze the tone of this review"
    ],
    input_modes: ["text"],
    output_modes: ["text", "data"]
  },
  {
    id: "entity-extraction",
    name: "Entity Extraction",
    description: "Extract named entities from text",
    tags: ["nlp", "ner", "entities"],
    examples: [
      "Find all people mentioned in this article",
      "Extract company names from this text"
    ],
    input_modes: ["text", "file"],
    output_modes: ["data"]
  }
]
```

## Capabilities Configuration

### Streaming Support

Enable if your agent can stream responses via SSE:

```ruby
capabilities: {
  streaming: true
}
```

### Push Notifications

Enable if your agent supports webhook callbacks:

```ruby
capabilities: {
  push_notifications: true
}
```

### State Transition History

Enable if you track and return full task state history:

```ruby
capabilities: {
  state_transition_history: true
}
```

## Best Practices

1. **Be Specific**: Clearly describe what your agent does
2. **Provide Examples**: Help users understand how to interact with your agent
3. **Use Tags**: Make your skills discoverable
4. **Version Properly**: Use semantic versioning
5. **Keep it Current**: Update when capabilities change

## Complete Example

```ruby
require 'a2a'

agent_card = A2A::Models::AgentCard.new(
  name: "Advanced NLP Agent",
  url: "https://nlp-agent.example.com/a2a",
  version: "3.2.1",
  description: "State-of-the-art natural language processing for multiple languages",

  provider: {
    organization: "NLP Technologies Inc.",
    url: "https://nlp-tech.com"
  },

  capabilities: {
    streaming: true,
    push_notifications: true,
    state_transition_history: false
  },

  authentication: {
    schemes: ["bearer"],
    credentials: "API keys available at https://nlp-tech.com/api-keys"
  },

  default_input_modes: ["text", "file"],
  default_output_modes: ["text", "data"],

  skills: [
    {
      id: "sentiment",
      name: "Sentiment Analysis",
      description: "Analyze emotional tone and sentiment",
      tags: ["sentiment", "emotion", "nlp"],
      examples: ["Analyze sentiment of: 'Great product!'"],
      input_modes: ["text"],
      output_modes: ["data"]
    },
    {
      id: "summarization",
      name: "Text Summarization",
      description: "Generate concise summaries",
      tags: ["summarization", "extraction", "nlp"],
      examples: ["Summarize this article in 3 sentences"],
      input_modes: ["text", "file"],
      output_modes: ["text"]
    }
  ]
)
```

## Next Steps

- [Working with Tasks](tasks.md) - Handle agent requests
- [Messages and Parts](messages.md) - Structure communication
- [Building a Server](../examples/server.md) - Implement an A2A server

---

[Back to Guides](index.md)
