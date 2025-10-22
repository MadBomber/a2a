<div align="center">
  <h1>A2A</h1>
  <img src="docs/assets/images/the_handshake.png" alt="The Handshake" width="600">
  <p>Agent to Agent Protocol</p>
  <p>
    <a href="https://badge.fury.io/rb/a2a">
      <img src="https://badge.fury.io/rb/a2a.svg" alt="Gem Version">
    </a>
    <img src="https://github.com/wilsonsilva/a2a/actions/workflows/main.yml/badge.svg" alt="Build">
    <a href="https://qlty.sh/gh/wilsonsilva/projects/a2a">
      <img src="https://qlty.sh/badges/73ebc4bb-d1db-4b5b-9a7c-a4acd59dfe69/maintainability.svg" alt="Maintainability">
    </a>
    <a href="https://qlty.sh/gh/wilsonsilva/projects/a2a">
      <img src="https://qlty.sh/badges/73ebc4bb-d1db-4b5b-9a7c-a4acd59dfe69/test_coverage.svg" alt="Code Coverage">
    </a>
  </p>
</div>

A Ruby implementation of the **A2A (Agent2Agent) protocol** - an open protocol enabling communication and interoperability between opaque agentic applications.

This gem provides a complete Ruby implementation of the A2A protocol specification, including:
- Core data models (Tasks, Messages, Artifacts, AgentCards)
- JSON-RPC 2.0 protocol implementation
- Base classes for building A2A clients and servers
- Full support for streaming, push notifications, and multi-turn conversations

## Table of Contents

- [Key Features](#-key-features)
- [Installation](#-installation)
- [Quickstart](#-quickstart)
- [Usage](#-usage)
  * [Creating Agent Cards](#creating-agent-cards)
  * [Working with Messages](#working-with-messages)
  * [Managing Tasks](#managing-tasks)
  * [Handling Artifacts](#handling-artifacts)
  * [Error Handling](#error-handling)
- [API Overview](#-api-overview)
- [Architecture](#-architecture)
- [Documentation](#-documentation)
- [Development](#-development)
  * [Type Checking](#type-checking)
- [Contributing](#-contributing)
- [License](#-license)
- [Code of Conduct](#-code-of-conduct)

## 🔑 Key Features

- **Complete Protocol Implementation**: Full implementation of the A2A JSON schema specification
- **Rich Data Models**: AgentCard, Task, Message, Artifact, and polymorphic Part types (Text, File, Data)
- **JSON-RPC 2.0**: Standards-compliant request/response messaging
- **Task Lifecycle Management**: Support for all task states (submitted, working, input-required, completed, failed, canceled)
- **Multi-turn Conversations**: Session support for ongoing agent interactions
- **Streaming Support**: Base classes ready for Server-Sent Events (SSE) implementation
- **Push Notifications**: Configuration support for webhook-based updates
- **Type Safety**: Designed to work with RBS type definitions
- **Extensible Architecture**: Clean separation of models, protocol, client, and server layers
- **Error Handling**: Comprehensive error hierarchy with JSON-RPC and A2A-specific errors

## 📦 Installation

Install the gem by executing:

    $ gem install a2a

## ⚡️ Quickstart

```ruby
require 'a2a'

# Create an agent card describing your agent
agent_card = A2A::Models::AgentCard.new(
  name: "My Agent",
  url: "https://example.com/a2a",
  version: "1.0.0",
  capabilities: {
    streaming: true,
    push_notifications: false
  },
  skills: [
    {
      id: "text-analysis",
      name: "Text Analysis",
      description: "Analyze and process text content"
    }
  ]
)

# Create a user message
message = A2A::Models::Message.text(
  role: "user",
  text: "Hello, agent! Can you help me analyze this text?"
)

# Create a task
task = A2A::Models::Task.new(
  id: "task-123",
  status: {
    state: "submitted"
  }
)

puts "Task #{task.id} is in state: #{task.state}"
# => Task task-123 is in state: submitted

# Create an artifact with results
artifact = A2A::Models::Artifact.new(
  name: "Analysis Results",
  parts: [
    A2A::Models::DataPart.new(
      data: {
        sentiment: "positive",
        word_count: 42,
        keywords: ["agent", "analysis", "text"]
      }
    )
  ]
)
```

See the [examples/basic_usage.rb](examples/basic_usage.rb) file for more comprehensive examples.

## 📖 Usage

### Creating Agent Cards

An AgentCard is a public metadata file describing an agent's capabilities:

```ruby
agent_card = A2A::Models::AgentCard.new(
  name: "Translation Agent",
  url: "https://api.example.com/translate",
  version: "2.0.0",
  description: "Translates text between multiple languages",
  capabilities: {
    streaming: true,
    push_notifications: true,
    state_transition_history: false
  },
  skills: [
    {
      id: "translate",
      name: "Translation",
      description: "Translate text between languages",
      tags: ["translation", "i18n"],
      examples: ["Translate 'hello' to Spanish"]
    }
  ],
  provider: {
    organization: "Example Corp",
    url: "https://example.com"
  }
)

# Serialize to JSON for serving at /.well-known/agent.json
require 'json'
puts JSON.pretty_generate(agent_card.to_h)
```

### Working with Messages

Messages represent communication turns between users and agents:

```ruby
# Simple text message
user_message = A2A::Models::Message.text(
  role: "user",
  text: "What's the weather like?"
)

# Message with multiple parts
agent_response = A2A::Models::Message.new(
  role: "agent",
  parts: [
    A2A::Models::TextPart.new(text: "Here's the weather forecast:"),
    A2A::Models::DataPart.new(
      data: {
        location: "San Francisco",
        temperature: 68,
        condition: "Sunny"
      }
    )
  ]
)

# Message with file content
file_message = A2A::Models::Message.new(
  role: "agent",
  parts: [
    A2A::Models::FilePart.new(
      file: {
        name: "report.pdf",
        mime_type: "application/pdf",
        uri: "https://example.com/files/report.pdf"
      }
    )
  ]
)
```

### Managing Tasks

Tasks are the central unit of work in A2A:

```ruby
# Create a new task
task = A2A::Models::Task.new(
  id: "task-#{SecureRandom.uuid}",
  session_id: "session-123",
  status: {
    state: "submitted",
    timestamp: Time.now.utc.iso8601
  }
)

# Check task state
puts task.state.submitted?  # => true
puts task.state.terminal?   # => false

# Update task status
task = A2A::Models::Task.new(
  id: task.id,
  status: {
    state: "working",
    message: A2A::Models::Message.text(
      role: "agent",
      text: "Processing your request..."
    )
  }
)

# Complete task with artifacts
completed_task = A2A::Models::Task.new(
  id: task.id,
  status: {
    state: "completed"
  },
  artifacts: [
    A2A::Models::Artifact.new(
      name: "Results",
      parts: [
        A2A::Models::TextPart.new(text: "Task completed successfully")
      ]
    )
  ]
)
```

### Handling Artifacts

Artifacts represent outputs generated by the agent:

```ruby
# Text artifact
text_artifact = A2A::Models::Artifact.new(
  name: "Summary",
  description: "Document summary",
  parts: [
    A2A::Models::TextPart.new(
      text: "This is a summary of the document..."
    )
  ]
)

# Structured data artifact
data_artifact = A2A::Models::Artifact.new(
  name: "Analysis",
  parts: [
    A2A::Models::DataPart.new(
      data: {
        entities: ["Person", "Organization", "Location"],
        sentiment: { score: 0.8, label: "positive" },
        keywords: ["AI", "agents", "protocol"]
      }
    )
  ],
  metadata: {
    model: "gpt-4",
    timestamp: Time.now.utc.iso8601
  }
)

# File artifact
file_artifact = A2A::Models::Artifact.new(
  name: "Generated Report",
  parts: [
    A2A::Models::FilePart.new(
      file: {
        name: "report.pdf",
        mime_type: "application/pdf",
        bytes: Base64.strict_encode64(file_content)
      }
    )
  ]
)
```

### Error Handling

The gem provides a complete error hierarchy:

```ruby
begin
  # Invalid task state
  state = A2A::Models::TaskState.new("invalid-state")
rescue ArgumentError => e
  puts "Error: #{e.message}"
end

begin
  # A2A protocol errors
  raise A2A::TaskNotFoundError
rescue A2A::JSONRPCError => e
  puts "Error code: #{e.code}"     # => -32001
  puts "Error message: #{e.message}" # => "Task not found"
end

# Available error types:
# - A2A::JSONParseError (code: -32700)
# - A2A::InvalidRequestError (code: -32600)
# - A2A::MethodNotFoundError (code: -32601)
# - A2A::InvalidParamsError (code: -32602)
# - A2A::InternalError (code: -32603)
# - A2A::TaskNotFoundError (code: -32001)
# - A2A::TaskNotCancelableError (code: -32002)
# - A2A::PushNotificationNotSupportedError (code: -32003)
# - A2A::UnsupportedOperationError (code: -32004)
```

## 🔌 API Overview

### Models (A2A::Models)

- **AgentCard** - Agent metadata and discovery
- **AgentCapabilities** - Agent capabilities (streaming, push notifications)
- **AgentSkill** - Individual agent skill
- **AgentProvider** - Provider information
- **AgentAuthentication** - Authentication configuration
- **Task** - Central unit of work
- **TaskStatus** - Task state and timestamp
- **TaskState** - Task state enum
- **Message** - Communication turn (user/agent)
- **Part** - Base class for content parts
- **TextPart** - Plain text content
- **FilePart** - File content (bytes or URI)
- **DataPart** - Structured JSON data
- **FileContent** - File representation
- **Artifact** - Agent-generated output
- **PushNotificationConfig** - Push notification settings

### Protocol (A2A::Protocol)

- **Request** - JSON-RPC request
- **Response** - JSON-RPC response
- **Error** - Protocol error representation

### Client & Server

- **A2A::Client::Base** - Base client class with methods for:
  - `discover()` - Fetch agent card
  - `send_task()` - Send task (synchronous)
  - `send_task_streaming()` - Send task with streaming
  - `get_task()` - Get task status
  - `cancel_task()` - Cancel task
  - `set_push_notification()` - Configure push notifications
  - `get_push_notification()` - Get notification config

- **A2A::Server::Base** - Base server class with handlers for:
  - `handle_send_task()` - Process tasks/send
  - `handle_send_task_streaming()` - Process tasks/sendSubscribe
  - `handle_get_task()` - Process tasks/get
  - `handle_cancel_task()` - Process tasks/cancel
  - `handle_set_push_notification()` - Process notification config
  - `handle_get_push_notification()` - Get notification config
  - `handle_resubscribe()` - Resubscribe to updates

## 🏗 Architecture

The gem is organized into clean, testable layers:

```
lib/a2a/
├── models/          # Data models from A2A spec
├── protocol/        # JSON-RPC implementation
├── client/          # Client base class
├── server/          # Server base class
└── utils/           # Utilities (future)
```

For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

### Design Principles

1. **Separation of Concerns** - Models, protocol, client, and server are cleanly separated
2. **Testability** - Each component is isolated and independently testable
3. **Extensibility** - Easy to add new part types, methods, or capabilities
4. **Type Safety** - Designed to work with RBS type definitions
5. **Protocol Compliance** - Strictly follows A2A JSON schema specification

## 📚 Documentation

- [YARD documentation](https://rubydoc.info/gems/a2a)
- [Architecture Guide](ARCHITECTURE.md)
- [A2A Protocol Specification](protocol_specification/README.md)
- [Example Usage](examples/basic_usage.rb)

## 🔨 Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`,
which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

The health and maintainability of the codebase is ensured through a set of
Rake tasks to test, lint and audit the gem for security vulnerabilities and documentation:

```
rake build                    # Build a2a.gem into the pkg directory
rake build:checksum           # Generate SHA512 checksum if a2a.gem into the checksums directory
rake bundle:audit:check       # Checks the Gemfile.lock for insecure dependencies
rake bundle:audit:update      # Updates the bundler-audit vulnerability database
rake clean                    # Remove any temporary products
rake clobber                  # Remove any generated files
rake coverage                 # Run spec with coverage
rake install                  # Build and install a2a.gem into system gems
rake install:local            # Build and install a2a.gem into system gems without network access
rake qa                       # Test, lint and perform security and documentation audits
rake release[remote]          # Create a tag, build and push a2a.gem to rubygems.org
rake rubocop                  # Run RuboCop
rake rubocop:autocorrect      # Autocorrect RuboCop offenses (only when it's safe)
rake rubocop:autocorrect_all  # Autocorrect RuboCop offenses (safe and unsafe)
rake spec                     # Run RSpec code examples
rake verify_measurements      # Verify that yardstick coverage is at least 100%
rake yard                     # Generate YARD Documentation
rake yard:junk                # Check the junk in your YARD Documentation
rake yardstick_measure        # Measure docs in lib/**/*.rb with yardstick
```

### Type checking

This gem leverages [RBS](https://github.com/ruby/rbs), a language to describe the structure of Ruby programs. It is
used to provide type checking and autocompletion in your editor. Run `bundle exec typeprof FILENAME` to generate
an RBS definition for the given Ruby file. And validate all definitions using [Steep](https://github.com/soutaro/steep)
with the command `bundle exec steep check`.

## 🐞 Issues & Bugs

If you find any issues or bugs, please report them [here](https://github.com/wilsonsilva/a2a/issues), I will be happy
to have a look at them and fix them as soon as possible.

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wilsonsilva/a2a.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere
to the [code of conduct](https://github.com/wilsonsilva/a2a/blob/main/CODE_OF_CONDUCT.md).

## 📜 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 👔 Code of Conduct

Everyone interacting in the A2A Ruby project's codebases, issue trackers, chat rooms and mailing lists is expected
to follow the [code of conduct](https://github.com/wilsonsilva/a2a/blob/main/CODE_OF_CONDUCT.md).
