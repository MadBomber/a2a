# API Reference

Complete API documentation for the A2A (Agent-to-Agent) Ruby gem.

## Overview

The A2A gem provides a Ruby implementation of the Agent-to-Agent protocol, enabling seamless communication and interoperability between autonomous agent applications. This reference documents all public classes, methods, and interfaces available in the gem.

## Quick Navigation

### Core Components

- **[Models](models.md)** - Data models for tasks, messages, artifacts, and agent cards
- **[Protocol](protocol.md)** - JSON-RPC protocol implementation for request/response handling
- **[Client](client.md)** - Client base class for consuming A2A services
- **[Server](server.md)** - Server base class for exposing A2A endpoints

## Architecture

The A2A gem is organized into four main layers:

### 1. Models Layer (`A2A::Models`)

Data structures representing the A2A protocol entities:

- **Task Management**: `Task`, `TaskStatus`, `TaskState`
- **Communication**: `Message`, `Artifact`, `Part` (and subclasses)
- **Agent Metadata**: `AgentCard`, `AgentCapabilities`, `AgentSkill`, `AgentProvider`, `AgentAuthentication`
- **Configuration**: `PushNotificationConfig`

[View Models Documentation](models.md)

### 2. Protocol Layer (`A2A::Protocol`)

JSON-RPC 2.0 protocol implementation:

- `Request` - JSON-RPC request representation
- `Response` - JSON-RPC response representation
- `Error` - Protocol error handling

[View Protocol Documentation](protocol.md)

### 3. Client Layer (`A2A::Client`)

Client implementation for consuming A2A services:

- Agent discovery via `/.well-known/agent.json`
- Task submission and management
- Streaming support
- Push notification configuration

[View Client Documentation](client.md)

### 4. Server Layer (`A2A::Server`)

Server implementation for exposing A2A endpoints:

- Request handling
- Task lifecycle management
- Streaming support
- Push notification support

[View Server Documentation](server.md)

## Error Handling

The gem defines a comprehensive error hierarchy based on JSON-RPC error codes:

### Base Errors

- `A2A::Error` - Base error class
- `A2A::JSONRPCError` - Base for all JSON-RPC errors (with code and data)

### Standard JSON-RPC Errors

| Error Class | Code | Description |
|-------------|------|-------------|
| `JSONParseError` | -32700 | Invalid JSON payload |
| `InvalidRequestError` | -32600 | Request payload validation error |
| `MethodNotFoundError` | -32601 | Method not found |
| `InvalidParamsError` | -32602 | Invalid parameters |
| `InternalError` | -32603 | Internal error |

### A2A-Specific Errors

| Error Class | Code | Description |
|-------------|------|-------------|
| `TaskNotFoundError` | -32001 | Task not found |
| `TaskNotCancelableError` | -32002 | Task cannot be canceled |
| `PushNotificationNotSupportedError` | -32003 | Push notifications not supported |
| `UnsupportedOperationError` | -32004 | Operation not supported |

## Common Patterns

### Creating a Message

```ruby
# Text message
message = A2A::Models::Message.text(
  role: 'user',
  text: 'Hello, agent!'
)

# Message with multiple parts
message = A2A::Models::Message.new(
  role: 'user',
  parts: [
    A2A::Models::TextPart.new(text: 'Please analyze this file:'),
    A2A::Models::FilePart.new(
      file: {
        name: 'data.csv',
        mime_type: 'text/csv',
        bytes: Base64.strict_encode64(File.read('data.csv'))
      }
    )
  ]
)
```

### Creating a Task

```ruby
task = A2A::Models::Task.new(
  id: SecureRandom.uuid,
  status: {
    state: 'submitted',
    timestamp: Time.now.utc.iso8601
  },
  session_id: 'session-123'
)
```

### Working with Artifacts

```ruby
artifact = A2A::Models::Artifact.new(
  name: 'analysis-results',
  description: 'Analysis of the provided data',
  parts: [
    A2A::Models::TextPart.new(text: 'Analysis complete.'),
    A2A::Models::DataPart.new(
      data: {
        summary: { total: 100, processed: 95 }
      }
    )
  ],
  index: 0
)
```

### Serialization

All model classes support JSON serialization:

```ruby
# To hash
hash = task.to_h

# To JSON string
json = task.to_json

# From hash
task = A2A::Models::Task.from_hash(hash)
```

## Version Information

```ruby
# Get gem version
A2A.version  # => "0.1.0" (or current version)
```

## Module Structure

```
A2A
├── VERSION               # Gem version constant
├── Error                 # Error classes
├── Models                # Data models
│   ├── Part              # Base class for message/artifact parts
│   │   ├── TextPart
│   │   ├── FilePart
│   │   └── DataPart
│   ├── FileContent       # File representation
│   ├── Message           # Communication turns
│   ├── Artifact          # Agent outputs
│   ├── TaskState         # Task state enumeration
│   ├── TaskStatus        # Task status with state and message
│   ├── Task              # Central unit of work
│   ├── AgentCard         # Agent metadata
│   ├── AgentCapabilities # Agent capabilities
│   ├── AgentSkill        # Agent skill definition
│   ├── AgentProvider     # Provider information
│   ├── AgentAuthentication # Auth configuration
│   └── PushNotificationConfig # Push notification settings
├── Protocol              # JSON-RPC protocol
│   ├── Request
│   ├── Response
│   └── Error
├── Client                # Client implementation
│   └── Base
└── Server                # Server implementation
    └── Base
```

## See Also

- [Installation Guide](../installation.md)
- [Quick Start](../quickstart.md)
- [Getting Started Guide](../guides/getting-started.md)
- [Architecture Documentation](../architecture/index.md)
- [GitHub Repository](https://github.com/madbomber/a2a)

---

[Back to Documentation Home](../index.md)
