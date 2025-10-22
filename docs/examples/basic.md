# Basic A2A Examples

This guide provides comprehensive examples of using the A2A gem's core data models. These examples cover all fundamental concepts you need to build A2A-compatible applications.

## Table of Contents

- [Overview](#overview)
- [AgentCard Examples](#agentcard-examples)
- [Message Examples](#message-examples)
- [Task Examples](#task-examples)
- [Artifact Examples](#artifact-examples)
- [Part Type Examples](#part-type-examples)
- [Error Handling](#error-handling)
- [JSON Serialization](#json-serialization)
- [Testing Patterns](#testing-patterns)
- [Complete Working Examples](#complete-working-examples)

## Overview

The A2A gem provides rich data models that implement the A2A protocol specification. All models support:

- **Immutable Construction**: Objects are created with all required data
- **JSON Serialization**: Automatic conversion to/from JSON
- **Validation**: Input validation with helpful error messages
- **Type Safety**: Clear interfaces and expected types
- **Testability**: Each model can be tested in isolation

### Core Models

The gem includes these primary models:

1. **AgentCard** - Agent metadata and capabilities
2. **Message** - Communication turns between user and agent
3. **Task** - The central unit of work with state management
4. **Artifact** - Agent-generated outputs
5. **Part** - Content components (Text, File, Data)
6. **TaskState** - Task state enumeration
7. **TaskStatus** - Task state with timestamp and optional message

## AgentCard Examples

An AgentCard describes an agent's capabilities and is typically served at `/.well-known/agent.json`.

### Example 1: Minimal AgentCard

```ruby
require 'a2a'

# Minimum required fields
agent = A2A::Models::AgentCard.new(
  name: "Simple Agent",
  url: "https://example.com/a2a",
  version: "1.0.0",
  capabilities: {
    streaming: false,
    push_notifications: false
  },
  skills: [
    {
      id: "help",
      name: "Help",
      description: "Provide help to users"
    }
  ]
)

puts agent.name
# => "Simple Agent"

puts agent.skills.first.name
# => "Help"

puts agent.capabilities.streaming?
# => false
```

### Example 2: Comprehensive AgentCard

```ruby
require 'a2a'
require 'debug_me'

# Full-featured AgentCard with all optional fields
agent = A2A::Models::AgentCard.new(
  # Required fields
  name: "Advanced Translation Agent",
  url: "https://api.example.com/a2a",
  version: "2.1.0",

  # Optional description
  description: "A sophisticated translation service supporting 50+ languages with context-aware translations",

  # Provider information
  provider: {
    organization: "Example Translation Corp",
    url: "https://example.com",
    support_email: "support@example.com"
  },

  # Documentation
  documentation_url: "https://docs.example.com/translation-api",

  # Capabilities
  capabilities: {
    streaming: true,
    push_notifications: true,
    state_transition_history: true
  },

  # Authentication
  authentication: {
    type: "bearer",
    description: "API key authentication via Authorization header"
  },

  # Input/Output modes
  default_input_modes: ['text', 'file'],
  default_output_modes: ['text', 'data'],

  # Skills
  skills: [
    {
      id: "translate",
      name: "Translation",
      description: "Translate text between languages",
      tags: ["translation", "i18n", "localization"],
      examples: [
        "Translate 'Hello' to Spanish",
        "Convert this document to French"
      ]
    },
    {
      id: "detect-language",
      name: "Language Detection",
      description: "Automatically detect the source language",
      tags: ["detection", "nlp"]
    },
    {
      id: "transliterate",
      name: "Transliteration",
      description: "Convert text between writing systems",
      tags: ["transliteration", "romanization"]
    }
  ]
)

# Access capabilities
debug_me "Agent supports streaming: #{agent.capabilities.streaming?}"
debug_me "Agent supports push notifications: #{agent.capabilities.push_notifications?}"

# Access skills
agent.skills.each do |skill|
  debug_me "Skill: #{skill.name} (#{skill.id})"
  debug_me "  Description: #{skill.description}"
  debug_me "  Tags: #{skill.tags.join(', ')}" if skill.tags
end

# Access provider
if agent.provider
  debug_me "Provider: #{agent.provider.organization}"
  debug_me "Support: #{agent.provider.support_email}"
end
```

### Example 3: Creating AgentCard from JSON

```ruby
require 'a2a'
require 'json'

# Load from JSON file (e.g., from /.well-known/agent.json)
json_data = File.read('agent.json')
agent_hash = JSON.parse(json_data, symbolize_names: true)

agent = A2A::Models::AgentCard.from_hash(agent_hash)

puts "Loaded agent: #{agent.name} v#{agent.version}"
puts "Skills: #{agent.skills.map(&:name).join(', ')}"
```

### Example 4: Serializing AgentCard to JSON

```ruby
require 'a2a'
require 'json'

agent = A2A::Models::AgentCard.new(
  name: "Example Agent",
  url: "https://example.com/a2a",
  version: "1.0.0",
  capabilities: { streaming: true },
  skills: [{ id: "help", name: "Help", description: "Get help" }]
)

# Convert to hash
agent_hash = agent.to_h

# Serialize to JSON
json = JSON.pretty_generate(agent_hash)
puts json

# Output:
# {
#   "name": "Example Agent",
#   "url": "https://example.com/a2a",
#   "version": "1.0.0",
#   "capabilities": {
#     "streaming": true,
#     "pushNotifications": false
#   },
#   "defaultInputModes": ["text"],
#   "defaultOutputModes": ["text"],
#   "skills": [
#     {
#       "id": "help",
#       "name": "Help",
#       "description": "Get help"
#     }
#   ]
# }

# Save to file
File.write('.well-known/agent.json', json)
```

## Message Examples

Messages represent communication turns between users and agents. Each message contains one or more Parts.

### Example 5: Simple Text Messages

```ruby
require 'a2a'

# User message with convenience method
user_msg = A2A::Models::Message.text(
  role: "user",
  text: "What's the weather like today?"
)

puts user_msg.role
# => "user"

puts user_msg.parts.first.text
# => "What's the weather like today?"

puts user_msg.parts.first.type
# => "text"

# Agent response
agent_msg = A2A::Models::Message.text(
  role: "agent",
  text: "The weather is sunny with a temperature of 72°F."
)

puts agent_msg.role
# => "agent"
```

### Example 6: Multi-Part Messages

```ruby
require 'a2a'

# Message with multiple parts
message = A2A::Models::Message.new(
  role: "agent",
  parts: [
    A2A::Models::TextPart.new(
      text: "Here are the search results:"
    ),
    A2A::Models::DataPart.new(
      data: {
        results: [
          { title: "Result 1", url: "https://example.com/1", relevance: 0.95 },
          { title: "Result 2", url: "https://example.com/2", relevance: 0.87 },
          { title: "Result 3", url: "https://example.com/3", relevance: 0.76 }
        ],
        total_count: 145,
        query: "ruby programming"
      }
    ),
    A2A::Models::TextPart.new(
      text: "Would you like me to refine these results?"
    )
  ]
)

# Access parts
message.parts.each_with_index do |part, i|
  puts "Part #{i + 1}: #{part.type}"

  case part
  when A2A::Models::TextPart
    puts "  Text: #{part.text}"
  when A2A::Models::DataPart
    puts "  Data keys: #{part.data.keys.join(', ')}"
  end
end
```

### Example 7: Messages with Metadata

```ruby
require 'a2a'

# Add metadata for context
message = A2A::Models::Message.text(
  role: "user",
  text: "Translate this to Spanish",
  metadata: {
    client: "mobile_app",
    version: "2.1.0",
    platform: "ios",
    locale: "en-US",
    user_id: "user-12345",
    request_id: "req-#{Time.now.to_i}",
    timestamp: Time.now.utc.iso8601
  }
)

# Access metadata
puts message.metadata[:platform]
# => "ios"

puts message.metadata[:client]
# => "mobile_app"
```

### Example 8: File Messages

```ruby
require 'a2a'
require 'base64'

# Message with file content (embedded bytes)
file_message = A2A::Models::Message.new(
  role: "user",
  parts: [
    A2A::Models::TextPart.new(
      text: "Please analyze this document"
    ),
    A2A::Models::FilePart.new(
      file: {
        name: "document.pdf",
        mime_type: "application/pdf",
        bytes: Base64.strict_encode64(File.read("document.pdf"))
      }
    )
  ]
)

# Message with file reference (URI)
file_ref_message = A2A::Models::Message.new(
  role: "user",
  parts: [
    A2A::Models::FilePart.new(
      file: {
        name: "large_video.mp4",
        mime_type: "video/mp4",
        uri: "https://storage.example.com/files/video-123.mp4"
      }
    )
  ]
)

# Accessing file information
file_part = file_message.parts[1]
puts file_part.file.name
# => "document.pdf"

puts file_part.file.mime_type
# => "application/pdf"

# Check if file has bytes or URI
if file_part.file.bytes
  puts "File embedded (#{file_part.file.bytes.length} bytes)"
elsif file_part.file.uri
  puts "File referenced: #{file_part.file.uri}"
end
```

## Task Examples

Tasks are the central unit of work in the A2A protocol. They track state and contain artifacts.

### Example 9: Creating Tasks

```ruby
require 'a2a'
require 'securerandom'

# Create a new task
task = A2A::Models::Task.new(
  id: SecureRandom.uuid,
  status: {
    state: "submitted"
  }
)

puts "Task ID: #{task.id}"
puts "Task state: #{task.state}"
puts "Is terminal? #{task.state.terminal?}"
# => false

# Task with session for multi-turn conversation
task_with_session = A2A::Models::Task.new(
  id: SecureRandom.uuid,
  session_id: SecureRandom.uuid,
  status: {
    state: "submitted",
    timestamp: Time.now.utc.iso8601
  }
)

puts "Session ID: #{task_with_session.session_id}"
```

### Example 10: Task State Transitions

```ruby
require 'a2a'
require 'securerandom'
require 'debug_me'

task_id = SecureRandom.uuid

# 1. Submitted state
task = A2A::Models::Task.new(
  id: task_id,
  status: { state: "submitted" }
)
debug_me "Task submitted: #{task.state}"

# 2. Working state
task = A2A::Models::Task.new(
  id: task_id,
  status: {
    state: "working",
    message: A2A::Models::Message.text(
      role: "agent",
      text: "Processing your request..."
    )
  }
)
debug_me "Task working: #{task.state}"

# 3. Input required state
task = A2A::Models::Task.new(
  id: task_id,
  status: {
    state: "input-required",
    message: A2A::Models::Message.text(
      role: "agent",
      text: "Which language would you like to translate to?"
    )
  }
)
debug_me "Task needs input: #{task.state.input_required?}"

# 4. Completed state with artifacts
task = A2A::Models::Task.new(
  id: task_id,
  status: { state: "completed" },
  artifacts: [
    A2A::Models::Artifact.new(
      name: "Translation",
      parts: [
        A2A::Models::TextPart.new(text: "Hola, mundo!")
      ]
    )
  ]
)
debug_me "Task completed: #{task.state.terminal?}"

# 5. Failed state
task = A2A::Models::Task.new(
  id: task_id,
  status: {
    state: "failed",
    message: A2A::Models::Message.text(
      role: "agent",
      text: "Translation service unavailable"
    )
  }
)
debug_me "Task failed: #{task.state.failed?}"

# 6. Canceled state
task = A2A::Models::Task.new(
  id: task_id,
  status: { state: "canceled" }
)
debug_me "Task canceled: #{task.state.canceled?}"
```

### Example 11: Task State Validation

```ruby
require 'a2a'

# All valid task states
valid_states = %w[
  submitted
  working
  input-required
  completed
  canceled
  failed
  unknown
]

valid_states.each do |state_name|
  state = A2A::Models::TaskState.new(state_name)
  puts "#{state_name}: terminal=#{state.terminal?}"
end

# Output:
# submitted: terminal=false
# working: terminal=false
# input-required: terminal=false
# completed: terminal=true
# canceled: terminal=true
# failed: terminal=true
# unknown: terminal=false

# Invalid state raises error
begin
  invalid_state = A2A::Models::TaskState.new("invalid")
rescue ArgumentError => e
  puts "Error: #{e.message}"
  # => "Invalid task state: invalid. Must be one of: submitted, working, ..."
end
```

### Example 12: Task with Metadata

```ruby
require 'a2a'
require 'securerandom'

# Add metadata for tracking and debugging
task = A2A::Models::Task.new(
  id: SecureRandom.uuid,
  session_id: SecureRandom.uuid,
  status: { state: "working" },
  metadata: {
    # Tracking information
    source: "web_app",
    user_id: "user-12345",
    organization_id: "org-456",

    # Priority and routing
    priority: "high",
    queue: "translation",
    worker: "worker-3",

    # Tags and categorization
    tags: ["translation", "spanish", "urgent"],
    category: "language_services",

    # Timing
    created_at: Time.now.utc.iso8601,
    deadline: (Time.now + 3600).utc.iso8601,

    # Correlation
    correlation_id: "req-789",
    parent_task_id: "task-parent-123",

    # Custom data
    estimated_duration: 30,
    language_pair: "en-es"
  }
)

# Access metadata
puts "Priority: #{task.metadata[:priority]}"
puts "Tags: #{task.metadata[:tags].join(', ')}"
puts "Estimated duration: #{task.metadata[:estimated_duration]}s"
```

## Artifact Examples

Artifacts represent outputs generated by the agent during task processing.

### Example 13: Simple Text Artifact

```ruby
require 'a2a'

# Basic text artifact
artifact = A2A::Models::Artifact.new(
  name: "Summary",
  description: "Document summary",
  parts: [
    A2A::Models::TextPart.new(
      text: "This document discusses the implementation of the A2A protocol..."
    )
  ]
)

puts artifact.name
# => "Summary"

puts artifact.parts.first.text
# => "This document discusses..."
```

### Example 14: Structured Data Artifact

```ruby
require 'a2a'

# Artifact with structured data
artifact = A2A::Models::Artifact.new(
  name: "Analysis Results",
  description: "Sentiment and entity analysis",
  parts: [
    A2A::Models::DataPart.new(
      data: {
        sentiment: {
          score: 0.85,
          label: "positive",
          confidence: 0.92
        },
        entities: [
          { text: "New York", type: "Location", confidence: 0.98 },
          { text: "Apple Inc", type: "Organization", confidence: 0.95 },
          { text: "Tim Cook", type: "Person", confidence: 0.97 }
        ],
        keywords: [
          { word: "technology", relevance: 0.89 },
          { word: "innovation", relevance: 0.76 }
        ],
        statistics: {
          word_count: 452,
          sentence_count: 23,
          paragraph_count: 5
        }
      }
    )
  ],
  metadata: {
    model: "gpt-4",
    processing_time_ms: 1234,
    timestamp: Time.now.utc.iso8601
  }
)

# Access data
data = artifact.parts.first.data
puts "Sentiment: #{data[:sentiment][:label]} (#{data[:sentiment][:score]})"
puts "Entities found: #{data[:entities].length}"
puts "Word count: #{data[:statistics][:word_count]}"
```

### Example 15: File Artifact

```ruby
require 'a2a'
require 'base64'

# Artifact with generated file
artifact = A2A::Models::Artifact.new(
  name: "Generated Report",
  description: "PDF report of analysis results",
  parts: [
    A2A::Models::FilePart.new(
      file: {
        name: "analysis_report.pdf",
        mime_type: "application/pdf",
        bytes: Base64.strict_encode64(File.read("report.pdf"))
      }
    )
  ]
)

# Or with URI reference for large files
artifact_with_uri = A2A::Models::Artifact.new(
  name: "Generated Video",
  description: "Promotional video",
  parts: [
    A2A::Models::FilePart.new(
      file: {
        name: "promo_video.mp4",
        mime_type: "video/mp4",
        uri: "https://storage.example.com/videos/promo-123.mp4"
      }
    )
  ],
  metadata: {
    duration_seconds: 120,
    resolution: "1920x1080",
    file_size_bytes: 45_678_901
  }
)
```

### Example 16: Multi-Part Artifact

```ruby
require 'a2a'

# Artifact with multiple parts (text + data + file)
artifact = A2A::Models::Artifact.new(
  name: "Complete Analysis",
  description: "Full analysis with summary, data, and visualizations",
  parts: [
    # Part 1: Text summary
    A2A::Models::TextPart.new(
      text: "Executive Summary:\n\nThe analysis reveals positive sentiment across all categories..."
    ),

    # Part 2: Structured data
    A2A::Models::DataPart.new(
      data: {
        overall_score: 0.87,
        category_scores: {
          product: 0.92,
          service: 0.85,
          support: 0.84
        },
        recommendations: [
          "Focus on maintaining high product quality",
          "Improve response time in support"
        ]
      }
    ),

    # Part 3: Visualization file
    A2A::Models::FilePart.new(
      file: {
        name: "sentiment_chart.png",
        mime_type: "image/png",
        uri: "https://storage.example.com/charts/sent-123.png"
      }
    )
  ]
)

# Iterate through parts
artifact.parts.each_with_index do |part, i|
  puts "Part #{i + 1} (#{part.type}):"

  case part
  when A2A::Models::TextPart
    puts "  #{part.text[0..50]}..."
  when A2A::Models::DataPart
    puts "  Data keys: #{part.data.keys.join(', ')}"
  when A2A::Models::FilePart
    puts "  File: #{part.file.name}"
  end
end
```

### Example 17: Streaming Artifacts

```ruby
require 'a2a'

# Artifact chunk for streaming (first chunk)
chunk1 = A2A::Models::Artifact.new(
  name: "Response",
  index: 0,
  append: false,
  last_chunk: false,
  parts: [
    A2A::Models::TextPart.new(
      text: "The answer to your question"
    )
  ]
)

# Second chunk (appending)
chunk2 = A2A::Models::Artifact.new(
  name: "Response",
  index: 0,
  append: true,
  last_chunk: false,
  parts: [
    A2A::Models::TextPart.new(
      text: " is that the A2A protocol"
    )
  ]
)

# Final chunk
chunk3 = A2A::Models::Artifact.new(
  name: "Response",
  index: 0,
  append: true,
  last_chunk: true,
  parts: [
    A2A::Models::TextPart.new(
      text: " enables agent interoperability."
    )
  ]
)

# Combine chunks
full_text = [chunk1, chunk2, chunk3]
  .map { |c| c.parts.first.text }
  .join

puts full_text
# => "The answer to your question is that the A2A protocol enables agent interoperability."
```

## Part Type Examples

Parts are the building blocks of Messages and Artifacts. There are three types: Text, File, and Data.

### Example 18: TextPart

```ruby
require 'a2a'

# Simple text part
text_part = A2A::Models::TextPart.new(
  text: "Hello, world!"
)

puts text_part.type
# => "text"

puts text_part.text
# => "Hello, world!"

# Text part with metadata
text_with_meta = A2A::Models::TextPart.new(
  text: "Important information",
  metadata: {
    language: "en",
    format: "plain",
    importance: "high"
  }
)

# Convert to hash
hash = text_with_meta.to_h
# => { type: "text", text: "Important information", metadata: { ... } }
```

### Example 19: DataPart

```ruby
require 'a2a'

# Simple data part
data_part = A2A::Models::DataPart.new(
  data: {
    temperature: 72,
    humidity: 45,
    condition: "sunny"
  }
)

puts data_part.type
# => "data"

puts data_part.data[:temperature]
# => 72

# Complex nested data
complex_data = A2A::Models::DataPart.new(
  data: {
    user: {
      id: "user-123",
      name: "John Doe",
      preferences: {
        language: "en",
        timezone: "America/New_York"
      }
    },
    results: [
      { id: 1, score: 0.95 },
      { id: 2, score: 0.87 }
    ],
    metadata: {
      timestamp: Time.now.utc.iso8601,
      version: "2.0"
    }
  }
)

# Access nested data
puts complex_data.data[:user][:name]
# => "John Doe"

puts complex_data.data[:results].first[:score]
# => 0.95
```

### Example 20: FilePart

```ruby
require 'a2a'
require 'base64'

# File with embedded bytes
file_with_bytes = A2A::Models::FilePart.new(
  file: {
    name: "image.png",
    mime_type: "image/png",
    bytes: Base64.strict_encode64(File.read("image.png"))
  }
)

puts file_with_bytes.type
# => "file"

puts file_with_bytes.file.name
# => "image.png"

# File with URI reference
file_with_uri = A2A::Models::FilePart.new(
  file: {
    name: "document.pdf",
    mime_type: "application/pdf",
    uri: "https://storage.example.com/docs/document-123.pdf"
  }
)

puts file_with_uri.file.uri
# => "https://storage.example.com/docs/document-123.pdf"

# File part with metadata
file_with_meta = A2A::Models::FilePart.new(
  file: {
    name: "video.mp4",
    mime_type: "video/mp4",
    uri: "https://cdn.example.com/video-456.mp4"
  },
  metadata: {
    duration_seconds: 120,
    resolution: "1920x1080",
    file_size_bytes: 45_678_901,
    codec: "h264"
  }
)
```

### Example 21: Creating Parts from Hash

```ruby
require 'a2a'

# The Part base class has a factory method
text_hash = {
  type: "text",
  text: "Hello"
}
text_part = A2A::Models::Part.from_hash(text_hash)
# => A2A::Models::TextPart

data_hash = {
  type: "data",
  data: { key: "value" }
}
data_part = A2A::Models::Part.from_hash(data_hash)
# => A2A::Models::DataPart

file_hash = {
  type: "file",
  file: {
    name: "file.txt",
    mimeType: "text/plain",
    uri: "https://example.com/file.txt"
  }
}
file_part = A2A::Models::Part.from_hash(file_hash)
# => A2A::Models::FilePart

# Unknown type raises error
begin
  invalid_hash = { type: "unknown" }
  A2A::Models::Part.from_hash(invalid_hash)
rescue ArgumentError => e
  puts e.message
  # => "Unknown part type: unknown"
end
```

## Error Handling

The A2A gem provides a comprehensive error hierarchy for handling protocol errors.

### Example 22: Error Types

```ruby
require 'a2a'

# All A2A errors inherit from A2A::Error
# JSON-RPC errors inherit from A2A::JSONRPCError

# 1. JSON Parse Error (-32700)
begin
  raise A2A::JSONParseError.new(data: { position: 42 })
rescue A2A::JSONRPCError => e
  puts "Code: #{e.code}"      # => -32700
  puts "Message: #{e.message}" # => "Invalid JSON payload"
  puts "Data: #{e.data}"      # => { position: 42 }
end

# 2. Invalid Request Error (-32600)
begin
  raise A2A::InvalidRequestError
rescue A2A::JSONRPCError => e
  puts "Code: #{e.code}"      # => -32600
  puts "Message: #{e.message}" # => "Request payload validation error"
end

# 3. Method Not Found Error (-32601)
begin
  raise A2A::MethodNotFoundError
rescue A2A::JSONRPCError => e
  puts "Code: #{e.code}"      # => -32601
  puts "Message: #{e.message}" # => "Method not found"
end

# 4. Invalid Params Error (-32602)
begin
  raise A2A::InvalidParamsError.new(
    data: { missing: ["taskId", "message"] }
  )
rescue A2A::JSONRPCError => e
  puts "Code: #{e.code}"      # => -32602
  puts "Message: #{e.message}" # => "Invalid parameters"
  puts "Missing: #{e.data[:missing]}" # => ["taskId", "message"]
end

# 5. Internal Error (-32603)
begin
  raise A2A::InternalError.new(data: { reason: "Database connection failed" })
rescue A2A::JSONRPCError => e
  puts "Code: #{e.code}"      # => -32603
  puts "Message: #{e.message}" # => "Internal error"
end

# 6. Task Not Found Error (-32001)
begin
  raise A2A::TaskNotFoundError
rescue A2A::JSONRPCError => e
  puts "Code: #{e.code}"      # => -32001
  puts "Message: #{e.message}" # => "Task not found"
end

# 7. Task Not Cancelable Error (-32002)
begin
  raise A2A::TaskNotCancelableError
rescue A2A::JSONRPCError => e
  puts "Code: #{e.code}"      # => -32002
  puts "Message: #{e.message}" # => "Task cannot be canceled"
end

# 8. Push Notification Not Supported Error (-32003)
begin
  raise A2A::PushNotificationNotSupportedError
rescue A2A::JSONRPCError => e
  puts "Code: #{e.code}"      # => -32003
  puts "Message: #{e.message}" # => "Push Notification is not supported"
end

# 9. Unsupported Operation Error (-32004)
begin
  raise A2A::UnsupportedOperationError
rescue A2A::JSONRPCError => e
  puts "Code: #{e.code}"      # => -32004
  puts "Message: #{e.message}" # => "This operation is not supported"
end
```

### Example 23: Error Handling Patterns

```ruby
require 'a2a'
require 'debug_me'

def safe_create_task(params)
  # Validate parameters
  unless params[:taskId]
    raise A2A::InvalidParamsError.new(
      data: { missing: "taskId", message: "Task ID is required" }
    )
  end

  unless params[:message]
    raise A2A::InvalidParamsError.new(
      data: { missing: "message", message: "Message is required" }
    )
  end

  # Create task
  task = A2A::Models::Task.new(
    id: params[:taskId],
    status: { state: "submitted" }
  )

  debug_me "Task created successfully: #{task.id}"
  task

rescue ArgumentError => e
  # Handle validation errors from model
  debug_me "Validation error: #{e.message}"
  raise A2A::InvalidParamsError.new(data: { reason: e.message })

rescue StandardError => e
  # Catch unexpected errors
  debug_me "Unexpected error: #{e.class} - #{e.message}"
  raise A2A::InternalError.new(data: { error: e.class.name })
end

# Usage
begin
  task = safe_create_task(taskId: "task-123", message: { role: "user" })
rescue A2A::JSONRPCError => e
  puts "Error code #{e.code}: #{e.message}"
  puts "Data: #{e.data}" if e.data
end
```

## JSON Serialization

All A2A models support bidirectional JSON serialization.

### Example 24: Serializing to JSON

```ruby
require 'a2a'
require 'json'

# Create a complete task with all features
task = A2A::Models::Task.new(
  id: "task-123",
  session_id: "session-456",
  status: {
    state: "completed",
    message: A2A::Models::Message.text(
      role: "agent",
      text: "Task completed successfully"
    ),
    timestamp: Time.now.utc.iso8601
  },
  artifacts: [
    A2A::Models::Artifact.new(
      name: "Results",
      parts: [
        A2A::Models::TextPart.new(text: "Here are the results"),
        A2A::Models::DataPart.new(data: { count: 42, status: "success" })
      ]
    )
  ],
  metadata: {
    priority: "high",
    tags: ["important"]
  }
)

# Convert to hash
task_hash = task.to_h

# Serialize to JSON
json = JSON.pretty_generate(task_hash)
puts json

# Compact JSON (no pretty printing)
compact_json = task.to_json
```

### Example 25: Deserializing from JSON

```ruby
require 'a2a'
require 'json'

# JSON string from API response
json_str = <<~JSON
  {
    "id": "task-789",
    "sessionId": "session-101",
    "status": {
      "state": "completed",
      "timestamp": "2024-01-15T10:30:00Z"
    },
    "artifacts": [
      {
        "name": "Translation",
        "parts": [
          {
            "type": "text",
            "text": "Hola, mundo!"
          }
        ]
      }
    ]
  }
JSON

# Parse JSON
hash = JSON.parse(json_str, symbolize_names: true)

# Create task from hash
task = A2A::Models::Task.from_hash(hash)

puts "Task ID: #{task.id}"
puts "State: #{task.state}"
puts "Artifact: #{task.artifacts.first.parts.first.text}"
```

### Example 26: Round-Trip Serialization

```ruby
require 'a2a'
require 'json'

# Create original message
original = A2A::Models::Message.new(
  role: "agent",
  parts: [
    A2A::Models::TextPart.new(text: "Hello"),
    A2A::Models::DataPart.new(data: { key: "value" })
  ],
  metadata: { timestamp: Time.now.utc.iso8601 }
)

# Serialize to JSON
json = original.to_json

# Deserialize back
hash = JSON.parse(json, symbolize_names: true)
restored = A2A::Models::Message.from_hash(hash)

# Verify equality
puts "Role match: #{original.role == restored.role}"
puts "Parts count match: #{original.parts.length == restored.parts.length}"
puts "First part text match: #{original.parts[0].text == restored.parts[0].text}"
puts "Second part data match: #{original.parts[1].data == restored.parts[1].data}"
```

## Testing Patterns

Examples of testing A2A models in isolation.

### Example 27: Unit Testing Models

```ruby
require 'a2a'
require 'minitest/autorun'

class TestTaskState < Minitest::Test
  def test_valid_states
    valid_states = %w[submitted working input-required completed canceled failed unknown]

    valid_states.each do |state_name|
      state = A2A::Models::TaskState.new(state_name)
      assert_equal state_name, state.to_s
    end
  end

  def test_terminal_states
    terminal_states = %w[completed canceled failed]

    terminal_states.each do |state_name|
      state = A2A::Models::TaskState.new(state_name)
      assert state.terminal?, "#{state_name} should be terminal"
    end
  end

  def test_non_terminal_states
    non_terminal = %w[submitted working input-required unknown]

    non_terminal.each do |state_name|
      state = A2A::Models::TaskState.new(state_name)
      refute state.terminal?, "#{state_name} should not be terminal"
    end
  end

  def test_invalid_state_raises_error
    assert_raises(ArgumentError) do
      A2A::Models::TaskState.new("invalid-state")
    end
  end

  def test_state_predicates
    submitted = A2A::Models::TaskState.new("submitted")
    assert submitted.submitted?
    refute submitted.working?

    working = A2A::Models::TaskState.new("working")
    assert working.working?
    refute working.completed?
  end
end

class TestMessage < Minitest::Test
  def test_text_convenience_method
    msg = A2A::Models::Message.text(role: "user", text: "Hello")

    assert_equal "user", msg.role
    assert_equal 1, msg.parts.length
    assert_instance_of A2A::Models::TextPart, msg.parts.first
    assert_equal "Hello", msg.parts.first.text
  end

  def test_invalid_role_raises_error
    assert_raises(ArgumentError) do
      A2A::Models::Message.text(role: "invalid", text: "Hello")
    end
  end

  def test_multi_part_message
    msg = A2A::Models::Message.new(
      role: "agent",
      parts: [
        A2A::Models::TextPart.new(text: "Text"),
        A2A::Models::DataPart.new(data: { key: "value" })
      ]
    )

    assert_equal 2, msg.parts.length
    assert_instance_of A2A::Models::TextPart, msg.parts[0]
    assert_instance_of A2A::Models::DataPart, msg.parts[1]
  end
end
```

### Example 28: Testing JSON Serialization

```ruby
require 'a2a'
require 'json'
require 'minitest/autorun'

class TestSerialization < Minitest::Test
  def test_task_serialization_round_trip
    original = A2A::Models::Task.new(
      id: "task-123",
      status: { state: "completed" }
    )

    # Serialize
    json = original.to_json
    hash = JSON.parse(json, symbolize_names: true)

    # Deserialize
    restored = A2A::Models::Task.from_hash(hash)

    assert_equal original.id, restored.id
    assert_equal original.state.to_s, restored.state.to_s
  end

  def test_message_with_metadata_serialization
    original = A2A::Models::Message.text(
      role: "user",
      text: "Hello",
      metadata: { key: "value", number: 42 }
    )

    json = original.to_json
    hash = JSON.parse(json, symbolize_names: true)
    restored = A2A::Models::Message.from_hash(hash)

    assert_equal original.metadata, restored.metadata
  end
end
```

## Complete Working Examples

### Example 29: Complete Conversation Workflow

```ruby
#!/usr/bin/env ruby
require 'a2a'
require 'securerandom'
require 'debug_me'

# Simulate a complete conversation workflow

# 1. Create agent card
agent_card = A2A::Models::AgentCard.new(
  name: "Translation Agent",
  url: "https://api.example.com/a2a",
  version: "1.0.0",
  capabilities: { streaming: false, push_notifications: false },
  skills: [
    { id: "translate", name: "Translation", description: "Translate text" }
  ]
)

debug_me "Agent: #{agent_card.name}"

# 2. Start a session
session_id = SecureRandom.uuid
debug_me "Session: #{session_id}"

# 3. First user message
user_msg_1 = A2A::Models::Message.text(
  role: "user",
  text: "Translate 'Hello, world!' to Spanish"
)

task_1 = A2A::Models::Task.new(
  id: SecureRandom.uuid,
  session_id: session_id,
  status: {
    state: "submitted",
    message: user_msg_1
  }
)

debug_me "Task 1 created: #{task_1.id}"

# 4. Agent processes and completes
task_1_completed = A2A::Models::Task.new(
  id: task_1.id,
  session_id: session_id,
  status: { state: "completed" },
  artifacts: [
    A2A::Models::Artifact.new(
      name: "Translation",
      parts: [
        A2A::Models::TextPart.new(text: "Hola, mundo!"),
        A2A::Models::DataPart.new(
          data: {
            source_language: "en",
            target_language: "es",
            confidence: 0.99
          }
        )
      ]
    )
  ]
)

debug_me "Task 1 completed"
debug_me "Translation: #{task_1_completed.artifacts.first.parts.first.text}"

# 5. Follow-up question in same session
user_msg_2 = A2A::Models::Message.text(
  role: "user",
  text: "Now translate it to French"
)

task_2 = A2A::Models::Task.new(
  id: SecureRandom.uuid,
  session_id: session_id,  # Same session
  status: {
    state: "submitted",
    message: user_msg_2
  }
)

debug_me "Task 2 created: #{task_2.id}"

# 6. Agent completes second task
task_2_completed = A2A::Models::Task.new(
  id: task_2.id,
  session_id: session_id,
  status: { state: "completed" },
  artifacts: [
    A2A::Models::Artifact.new(
      name: "Translation",
      parts: [
        A2A::Models::TextPart.new(text: "Bonjour, le monde!"),
        A2A::Models::DataPart.new(
          data: {
            source_language: "en",
            target_language: "fr",
            confidence: 0.98
          }
        )
      ]
    )
  ]
)

debug_me "Task 2 completed"
debug_me "Translation: #{task_2_completed.artifacts.first.parts.first.text}"

debug_me "Conversation completed successfully"
```

### Example 30: Error Recovery Workflow

```ruby
#!/usr/bin/env ruby
require 'a2a'
require 'securerandom'
require 'debug_me'

def process_user_request(text)
  task_id = SecureRandom.uuid
  debug_me "Processing request: #{task_id}"

  # Create message
  message = A2A::Models::Message.text(role: "user", text: text)

  # Create task
  task = A2A::Models::Task.new(
    id: task_id,
    status: { state: "submitted", message: message }
  )

  # Simulate processing
  begin
    # This might raise an error
    result = perform_translation(text)

    # Success
    A2A::Models::Task.new(
      id: task_id,
      status: { state: "completed" },
      artifacts: [
        A2A::Models::Artifact.new(
          name: "Translation",
          parts: [A2A::Models::TextPart.new(text: result)]
        )
      ]
    )

  rescue StandardError => e
    # Error handling
    debug_me "Error: #{e.message}"

    A2A::Models::Task.new(
      id: task_id,
      status: {
        state: "failed",
        message: A2A::Models::Message.text(
          role: "agent",
          text: "Sorry, translation failed: #{e.message}"
        )
      }
    )
  end
end

def perform_translation(text)
  # Simulate translation
  raise "Translation service unavailable" if text.empty?
  "Translated: #{text}"
end

# Test success case
task1 = process_user_request("Hello")
debug_me "Task 1 state: #{task1.state}"
debug_me "Result: #{task1.artifacts&.first&.parts&.first&.text}"

# Test error case
task2 = process_user_request("")
debug_me "Task 2 state: #{task2.state}"
debug_me "Error message: #{task2.status.message.parts.first.text}"
```

## Summary

This guide covered all fundamental aspects of the A2A gem's data models:

1. **AgentCard** - Creating and serializing agent metadata
2. **Messages** - Building user and agent messages with various content types
3. **Tasks** - Managing task lifecycle and states
4. **Artifacts** - Generating outputs with different part types
5. **Parts** - Working with Text, File, and Data parts
6. **Errors** - Handling protocol errors properly
7. **JSON** - Serializing and deserializing models
8. **Testing** - Testing models in isolation

### Next Steps

- **[Client Examples](client.md)** - Learn how to build A2A HTTP clients
- **[Server Examples](server.md)** - Learn how to build A2A HTTP servers
- **[Examples Index](index.md)** - Return to examples overview

### Key Takeaways

- All models are immutable - create new instances for updates
- Use `to_h` and `to_json` for serialization
- Use `from_hash` for deserialization
- Validate input early and provide helpful error messages
- Use `debug_me` gem for debugging instead of `puts`
- Test each model and method in isolation
- Always use unique task IDs (SecureRandom.uuid)
- Add metadata for tracking and debugging

---

[Back to Examples Index](index.md) | [Back to Documentation Home](../index.md)
