# A2A Ruby Gem Architecture

## Overview

This Ruby gem implements the A2A (Agent to Agent) protocol, an open protocol enabling communication and interoperability between agentic applications. The protocol uses JSON-RPC 2.0 for message exchange.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        A2A Gem                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐         ┌──────────────┐                  │
│  │   Client     │◄───────►│   Server     │                  │
│  │    Base      │         │    Base      │                  │
│  └──────────────┘         └──────────────┘                  │
│         │                         │                         │
│         │                         │                         │
│         ▼                         ▼                         │
│  ┌─────────────────────────────────────────┐                │
│  │           Protocol Layer                │                │
│  │  ┌─────────┐  ┌──────────┐  ┌────────┐  │                │
│  │  │ Request │  │ Response │  │ Error  │  │                │
│  │  └─────────┘  └──────────┘  └────────┘  │                │
│  └─────────────────────────────────────────┘                │
│         │                         │                         │
│         │                         │                         │
│         ▼                         ▼                         │
│  ┌─────────────────────────────────────────┐                │
│  │            Models Layer                 │                │
│  │  ┌──────────────┐  ┌──────────────┐     │                │
│  │  │  AgentCard   │  │    Task      │     │                │
│  │  │ Capabilities │  │   Status     │     │                │
│  │  │    Skills    │  │   Message    │     │                │
│  │  └──────────────┘  └──────────────┘     │                │
│  │  ┌──────────────┐  ┌──────────────┐     │                │
│  │  │    Parts     │  │  Artifacts   │     │                │
│  │  │ Text/File/   │  │              │     │                │
│  │  │    Data      │  │              │     │                │
│  │  └──────────────┘  └──────────────┘     │                │
│  └─────────────────────────────────────────┘                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
lib/a2a/
├── version.rb                  # Gem version
├── error.rb                    # Error classes (JSON-RPC and A2A specific)
│
├── models/                     # Data models from A2A protocol specification
│   ├── agent_card.rb           # Agent metadata and discovery
│   ├── agent_capabilities.rb   # Agent capabilities (streaming, push notifications)
│   ├── agent_skill.rb          # Agent skill definition
│   ├── agent_provider.rb       # Agent provider information
│   ├── agent_authentication.rb # Authentication configuration
│   ├── task.rb                 # Task (central unit of work)
│   ├── task_status.rb          # Task status with state and timestamp
│   ├── task_state.rb           # Task state enum (submitted, working, etc.)
│   ├── message.rb              # Communication turns (user/agent)
│   ├── part.rb                 # Base class for message parts
│   ├── text_part.rb            # Text content part
│   ├── file_part.rb            # File content part
│   ├── file_content.rb         # File representation (bytes or URI)
│   ├── data_part.rb            # Structured data part (JSON)
│   ├── artifact.rb             # Agent-generated outputs
│   └── push_notification_config.rb # Push notification configuration
│
├── protocol/                  # JSON-RPC protocol implementation
│   ├── request.rb             # Base JSON-RPC request
│   ├── response.rb            # Base JSON-RPC response
│   ├── error.rb               # Protocol error representation
│   ├── requests/              # Specific request types (future)
│   ├── responses/             # Specific response types (future)
│   ├── events/                # SSE events (future)
│   └── errors/                # Specific error types (future)
│
├── client/                    # A2A Client implementation
│   └── base.rb                # Base client class
│
├── server/                    # A2A Server implementation
│   └── base.rb                # Base server class
│
└── utils/                     # Utilities (future)
    ├── json_schema_validator.rb
    └── serializer.rb
```

## Core Components

### 1. Models Layer

#### AgentCard
- Represents an agent's metadata and capabilities
- Usually served at `/.well-known/agent.json`
- Contains: name, URL, version, capabilities, skills, authentication

#### Task
- Central unit of work in A2A protocol
- Has unique ID and progresses through states
- States: submitted, working, input-required, completed, failed, canceled

#### Message
- Represents communication turns between client (user) and agent
- Contains an array of Parts (text, file, or data)

#### Parts (Polymorphic)
- **TextPart**: Plain text content
- **FilePart**: File content (bytes or URI reference)
- **DataPart**: Structured JSON data (e.g., forms)

#### Artifact
- Represents outputs generated by the agent
- Contains Parts similar to Messages

### 2. Protocol Layer

Implements JSON-RPC 2.0 specification:

#### Request
- Standard JSON-RPC request format
- Contains: jsonrpc, id, method, params

#### Response
- Standard JSON-RPC response format
- Contains: jsonrpc, id, result or error

#### Error
- JSON-RPC error representation
- Includes standard and A2A-specific error codes

### 3. Client Layer

**Base Client** provides interface for:
- `discover()` - Fetch agent card from well-known URL
- `send_task()` - Send a task to agent (synchronous)
- `send_task_streaming()` - Send task with streaming (SSE)
- `get_task()` - Get task status
- `cancel_task()` - Cancel a running task
- `set_push_notification()` - Configure push notifications
- `get_push_notification()` - Get push notification config

### 4. Server Layer

**Base Server** provides interface for handling:
- `handle_send_task()` - Process tasks/send
- `handle_send_task_streaming()` - Process tasks/sendSubscribe (SSE)
- `handle_get_task()` - Process tasks/get
- `handle_cancel_task()` - Process tasks/cancel
- `handle_set_push_notification()` - Process tasks/pushNotification/set
- `handle_get_push_notification()` - Process tasks/pushNotification/get
- `handle_resubscribe()` - Process tasks/resubscribe

## Protocol Methods

### Core Methods
- `tasks/send` - Send a task to agent (synchronous)
- `tasks/sendSubscribe` - Send task with streaming support
- `tasks/get` - Get current task status
- `tasks/cancel` - Cancel a task
- `tasks/pushNotification/set` - Set push notification config
- `tasks/pushNotification/get` - Get push notification config
- `tasks/resubscribe` - Resubscribe to streaming updates

## Design Principles

1. **Separation of Concerns**: Models, protocol, client, and server are cleanly separated
2. **Testability**: Each component is isolated and independently testable
3. **Extensibility**: Easy to add new part types, methods, or capabilities
4. **Type Safety**: Designed to work with RBS type definitions
5. **Protocol Compliance**: Strictly follows A2A JSON schema specification

## Future Enhancements

1. **HTTP Client Implementation**: Concrete client using net/http or faraday
2. **Rack Server Implementation**: Rack-based server for easy integration
3. **SSE Support**: Server-Sent Events for streaming
4. **JSON Schema Validation**: Validate all messages against protocol schema
5. **Webhook Support**: Push notification delivery
6. **Authentication Handlers**: Support for various auth schemes
7. **Logging and Debugging**: Comprehensive logging support

## Usage Examples

### Creating an Agent Card

```ruby
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
      id: "skill-1",
      name: "Text Processing",
      description: "Process and analyze text"
    }
  ]
)
```

### Creating a Task

```ruby
message = A2A::Models::Message.text(
  role: "user",
  text: "Hello, agent!"
)

task = A2A::Models::Task.new(
  id: "task-123",
  status: {
    state: "submitted"
  }
)
```

### Error Handling

```ruby
begin
  # Some A2A operation
rescue A2A::TaskNotFoundError => e
  puts "Task not found: #{e.message}"
  puts "Error code: #{e.code}"
rescue A2A::JSONRPCError => e
  puts "Protocol error: #{e.message}"
end
```

## Contributing

When adding new features:
1. Add models to `lib/a2a/models/`
2. Add protocol messages to `lib/a2a/protocol/`
3. Update main `lib/a2a.rb` to require new files
4. Add tests in `spec/`
5. Update this architecture document

## References

- [A2A Protocol Specification](../protocol-spec.md)
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
- [A2A JSON Schema](https://google.github.io/A2A/#/specification)
