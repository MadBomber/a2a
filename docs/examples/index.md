# A2A Examples

This section provides comprehensive, practical examples for building Agent2Agent (A2A) protocol implementations using the A2A Ruby gem. Each example is designed to be copy-paste-ready and production-quality.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Example Categories](#example-categories)
- [Getting Started](#getting-started)
- [Common Patterns](#common-patterns)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

## Overview

The A2A protocol enables communication and interoperability between opaque agentic applications. This gem provides a complete Ruby implementation of the A2A protocol specification, including:

- **Core Data Models**: Tasks, Messages, Artifacts, AgentCards
- **JSON-RPC 2.0 Protocol**: Standards-compliant request/response messaging
- **Client Base Classes**: For consuming A2A services
- **Server Base Classes**: For providing A2A services
- **Streaming Support**: Server-Sent Events (SSE) for real-time updates
- **Push Notifications**: Webhook-based task status updates

### What is A2A?

A2A (Agent2Agent) is an open protocol that enables:

1. **Agent Discovery**: Through AgentCard metadata files
2. **Task Management**: Submit, monitor, and cancel agent tasks
3. **Multi-turn Conversations**: Session-based interactions
4. **Real-time Streaming**: Server-sent events for live updates
5. **Push Notifications**: Webhook callbacks for status changes
6. **Rich Content**: Text, files, and structured data in messages

### Architecture Overview

```
┌─────────────┐                           ┌─────────────┐
│   A2A       │   HTTP/JSON-RPC 2.0      │   A2A       │
│   Client    │─────────────────────────>│   Server    │
│             │                           │             │
│ - Discover  │                           │ - AgentCard │
│ - SendTask  │                           │ - Process   │
│ - GetTask   │                           │ - Stream    │
│ - Cancel    │                           │ - Notify    │
└─────────────┘                           └─────────────┘
```

## Prerequisites

Before starting with these examples, ensure you have:

### System Requirements

- Ruby 3.0 or higher
- Bundler 2.0 or higher
- Basic understanding of HTTP and JSON-RPC

### Installation

Install the A2A gem:

```bash
gem install a2a
```

Or add to your Gemfile:

```ruby
gem 'a2a'
```

Then run:

```bash
bundle install
```

### Required Dependencies

For the examples in this guide, you may also need:

```ruby
# For HTTP clients
gem 'faraday'
gem 'net-http'

# For servers
gem 'sinatra'
gem 'puma'
gem 'rack'

# For SSE streaming (optional)
gem 'sinatra-sse'

# For JSON handling
gem 'json'

# For debugging (as per your requirements)
gem 'debug_me', git: 'https://github.com/madbomber/debug_me'
```

## Example Categories

This documentation is organized into the following categories:

### 1. [Basic Examples](basic.md)

Learn the fundamentals of the A2A gem:

- Creating AgentCards
- Working with Messages and Parts
- Managing Tasks and States
- Handling Artifacts
- Error handling patterns
- JSON serialization/deserialization
- Testing models in isolation

**Who should read this**: Everyone starting with A2A

**Key concepts covered**:
- Data model fundamentals
- Object creation and manipulation
- State management
- Error handling

### 2. [Client Examples](client.md)

Build production-ready A2A HTTP clients:

- Subclassing `A2A::Client::Base`
- Implementing agent discovery
- Sending tasks (synchronous)
- Streaming task updates (SSE)
- Polling for task status
- Canceling tasks
- Configuring push notifications
- Error handling and retries
- Complete working examples with Faraday and Net::HTTP

**Who should read this**: Developers building applications that consume A2A services

**Key concepts covered**:
- HTTP client implementation
- JSON-RPC request/response handling
- SSE streaming
- Connection management
- Authentication

### 3. [Server Examples](server.md)

Build production-ready A2A HTTP servers:

- Subclassing `A2A::Server::Base`
- Serving AgentCards
- Processing tasks
- Implementing streaming responses
- Push notification callbacks
- Request routing and validation
- Complete working Sinatra/Rack server examples
- Production deployment patterns

**Who should read this**: Developers building A2A-compatible agent services

**Key concepts covered**:
- HTTP server implementation
- JSON-RPC method routing
- SSE streaming
- Background job processing
- Production deployment

## Getting Started

### Quick Start: 30 Seconds to A2A

Here's the fastest way to get started with A2A:

```ruby
require 'a2a'

# Create an agent card
agent = A2A::Models::AgentCard.new(
  name: "Quick Agent",
  url: "https://example.com/a2a",
  version: "1.0.0",
  capabilities: { streaming: true },
  skills: [{ id: "help", name: "Help", description: "Get help" }]
)

# Create a message
message = A2A::Models::Message.text(role: "user", text: "Hello!")

# Create a task
task = A2A::Models::Task.new(
  id: "task-123",
  status: { state: "submitted" }
)

puts "Agent: #{agent.name}"
puts "Message: #{message.parts.first.text}"
puts "Task state: #{task.state}"
```

### Recommended Learning Path

1. **Start with Basic Examples** ([basic.md](basic.md))
   - Understand the data models
   - Learn object creation patterns
   - Practice JSON serialization

2. **Build a Simple Client** ([client.md](client.md))
   - Implement agent discovery
   - Send synchronous tasks
   - Handle responses

3. **Add Streaming Support**
   - Implement SSE streaming in client
   - Handle real-time updates

4. **Build a Simple Server** ([server.md](server.md))
   - Serve AgentCard
   - Process basic tasks
   - Return results

5. **Add Advanced Features**
   - Streaming responses
   - Push notifications
   - Multi-turn conversations

## Common Patterns

### Pattern 1: Creating Structured Messages

Messages in A2A can contain multiple parts with different content types:

```ruby
# Simple text message
text_msg = A2A::Models::Message.text(
  role: "user",
  text: "Analyze this document"
)

# Multi-part message with text and data
mixed_msg = A2A::Models::Message.new(
  role: "agent",
  parts: [
    A2A::Models::TextPart.new(text: "Analysis complete:"),
    A2A::Models::DataPart.new(
      data: {
        sentiment: "positive",
        entities: ["Person", "Location"],
        confidence: 0.95
      }
    )
  ]
)

# Message with file attachment
file_msg = A2A::Models::Message.new(
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

### Pattern 2: Task Lifecycle Management

Understanding and managing task states:

```ruby
# Create a new task
task = A2A::Models::Task.new(
  id: SecureRandom.uuid,
  session_id: session_id,
  status: {
    state: "submitted",
    timestamp: Time.now.utc.iso8601
  }
)

# Update to working state
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

# Check if task is in terminal state
unless task.state.terminal?
  # Task is still active
end

# Complete task with results
task = A2A::Models::Task.new(
  id: task.id,
  status: { state: "completed" },
  artifacts: [
    A2A::Models::Artifact.new(
      name: "Results",
      parts: [A2A::Models::TextPart.new(text: "Done!")]
    )
  ]
)
```

### Pattern 3: Error Handling

Proper error handling in A2A applications:

```ruby
begin
  # Attempt to process a task
  result = process_task(params)

rescue A2A::TaskNotFoundError => e
  # Handle missing task
  response = A2A::Protocol::Response.error(
    id: request_id,
    error: { code: e.code, message: e.message }
  )

rescue A2A::InvalidParamsError => e
  # Handle invalid parameters
  response = A2A::Protocol::Response.error(
    id: request_id,
    error: { code: e.code, message: e.message, data: e.data }
  )

rescue A2A::InternalError => e
  # Handle internal errors
  debug_me "Internal error occurred: #{e.message}"
  response = A2A::Protocol::Response.error(
    id: request_id,
    error: { code: e.code, message: "Internal server error" }
  )

rescue StandardError => e
  # Catch-all for unexpected errors
  debug_me "Unexpected error: #{e.class} - #{e.message}"
  error_response = A2A::Protocol::Response.error(
    id: request_id,
    error: {
      code: -32603,
      message: "Internal error",
      data: { type: e.class.name }
    }
  )
end
```

### Pattern 4: JSON-RPC Request/Response

Creating and handling JSON-RPC messages:

```ruby
# Create a request
request = A2A::Protocol::Request.new(
  method: "tasks/send",
  params: {
    taskId: "task-123",
    message: message.to_h
  },
  id: SecureRandom.uuid
)

# Serialize to JSON
json_payload = request.to_json

# Parse response
response_data = JSON.parse(response_body, symbolize_names: true)
response = A2A::Protocol::Response.from_hash(response_data)

if response.success?
  task = A2A::Models::Task.from_hash(response.result)
else
  error = response.error
  raise A2A::JSONRPCError.new(error[:message], code: error[:code])
end
```

### Pattern 5: Streaming with SSE

Handling Server-Sent Events for real-time updates:

```ruby
# Client-side streaming handler
def handle_streaming_task(task_id, message)
  request = A2A::Protocol::Request.new(
    method: "tasks/sendSubscribe",
    params: {
      taskId: task_id,
      message: message.to_h
    }
  )

  # Connect to SSE endpoint
  EventSource.new("#{agent_url}/a2a/events") do |source|
    source.on_message do |event|
      data = JSON.parse(event.data, symbolize_names: true)

      case data[:type]
      when "taskStatus"
        task = A2A::Models::Task.from_hash(data[:task])
        yield :status, task

      when "artifactUpdate"
        artifact = A2A::Models::Artifact.from_hash(data[:artifact])
        yield :artifact, artifact

      when "taskComplete"
        task = A2A::Models::Task.from_hash(data[:task])
        yield :complete, task
        source.close
      end
    end
  end
end
```

### Pattern 6: Session Management

Managing multi-turn conversations:

```ruby
class ConversationSession
  attr_reader :session_id, :task_history

  def initialize
    @session_id = SecureRandom.uuid
    @task_history = []
  end

  def send_message(client, text)
    message = A2A::Models::Message.text(role: "user", text: text)

    task = client.send_task(
      task_id: SecureRandom.uuid,
      message: message,
      session_id: session_id
    )

    @task_history << task
    task
  end

  def get_conversation_history
    task_history.flat_map do |task|
      messages = []

      # Add user message if present in task
      messages << task.status.message if task.status.message

      # Add agent responses from artifacts
      task.artifacts&.each do |artifact|
        messages << create_agent_message(artifact)
      end

      messages
    end.compact
  end

  private

  def create_agent_message(artifact)
    A2A::Models::Message.new(
      role: "agent",
      parts: artifact.parts
    )
  end
end
```

## Best Practices

### 1. Always Validate Input

```ruby
def validate_task_params(params)
  raise A2A::InvalidParamsError unless params[:taskId]
  raise A2A::InvalidParamsError unless params[:message]

  # Validate message structure
  message = A2A::Models::Message.from_hash(params[:message])
rescue ArgumentError => e
  raise A2A::InvalidParamsError.new(data: { reason: e.message })
end
```

### 2. Use Unique Task IDs

```ruby
require 'securerandom'

# Always generate unique task IDs
task_id = SecureRandom.uuid
# => "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"

# Or use a more specific format
task_id = "task-#{Time.now.to_i}-#{SecureRandom.hex(4)}"
# => "task-1634567890-a3f2"
```

### 3. Implement Proper Timeout Handling

```ruby
require 'timeout'

def send_task_with_timeout(client, task_id, message, timeout: 30)
  Timeout.timeout(timeout) do
    client.send_task(task_id: task_id, message: message)
  end
rescue Timeout::Error
  debug_me "Task #{task_id} timed out after #{timeout} seconds"
  raise A2A::InternalError.new(data: { reason: "Request timeout" })
end
```

### 4. Use Metadata for Context

```ruby
# Add metadata to tasks for tracking
task = A2A::Models::Task.new(
  id: task_id,
  status: { state: "submitted" },
  metadata: {
    source: "web_app",
    user_id: "user-123",
    priority: "high",
    tags: ["customer-support", "urgent"],
    created_at: Time.now.utc.iso8601,
    correlation_id: request_id
  }
)

# Add metadata to messages for context
message = A2A::Models::Message.text(
  role: "user",
  text: "Help me with this issue",
  metadata: {
    client_version: "1.2.3",
    platform: "ios",
    locale: "en-US"
  }
)
```

### 5. Implement Graceful Degradation

```ruby
def send_task_with_fallback(client, task_id, message)
  # Try streaming first if supported
  if client.agent_card&.capabilities&.streaming?
    begin
      send_task_streaming(client, task_id, message)
    rescue A2A::UnsupportedOperationError
      # Fallback to synchronous
      send_task_sync(client, task_id, message)
    end
  else
    send_task_sync(client, task_id, message)
  end
end
```

### 6. Log Everything for Debugging

```ruby
require 'debug_me'

def process_task(params)
  debug_me "Processing task: #{params[:taskId]}"

  begin
    task = execute_task(params)
    debug_me { [ :task, :task.id, :task.state ] }
    task
  rescue => e
    debug_me "Error processing task: #{e.class} - #{e.message}"
    raise
  end
end
```

### 7. Test Models in Isolation

```ruby
# Each method should be easily testable
class TaskProcessor
  def validate_params(params)
    # Isolated validation logic
    raise ArgumentError, "Missing taskId" unless params[:taskId]
    raise ArgumentError, "Missing message" unless params[:message]
    params
  end

  def create_task(params)
    # Isolated task creation
    A2A::Models::Task.new(
      id: params[:taskId],
      status: { state: "submitted" }
    )
  end

  def process(params)
    validated = validate_params(params)
    task = create_task(validated)
    execute_task(task)
  end
end
```

### 8. Handle State Transitions Carefully

```ruby
def update_task_state(task, new_state, message: nil)
  # Validate state transition
  unless valid_transition?(task.state.to_s, new_state)
    raise A2A::InvalidParamsError.new(
      data: {
        reason: "Invalid state transition",
        from: task.state.to_s,
        to: new_state
      }
    )
  end

  # Create new task with updated state
  A2A::Models::Task.new(
    id: task.id,
    session_id: task.session_id,
    status: {
      state: new_state,
      timestamp: Time.now.utc.iso8601,
      message: message
    },
    artifacts: task.artifacts,
    metadata: task.metadata
  )
end

def valid_transition?(from_state, to_state)
  transitions = {
    "submitted" => %w[working canceled failed],
    "working" => %w[input-required completed failed canceled],
    "input-required" => %w[working completed failed canceled]
  }

  transitions[from_state]&.include?(to_state) || false
end
```

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Invalid JSON Payload

**Problem**: Receiving `-32700` JSON parse errors

**Solution**:
```ruby
begin
  data = JSON.parse(request.body.read, symbolize_names: true)
rescue JSON::ParserError => e
  return A2A::Protocol::Response.error(
    id: nil,
    error: {
      code: -32700,
      message: "Invalid JSON payload",
      data: { reason: e.message }
    }
  )
end
```

#### Issue 2: Task Not Found

**Problem**: `-32001` errors when querying tasks

**Solution**:
```ruby
class TaskStore
  def initialize
    @tasks = {}
  end

  def find(task_id)
    @tasks[task_id] or raise A2A::TaskNotFoundError
  end

  def save(task)
    @tasks[task.id] = task
  end
end
```

#### Issue 3: Streaming Connection Drops

**Problem**: SSE connections closing unexpectedly

**Solution**:
```ruby
# Keep connection alive with heartbeat
def stream_task_updates(task_id)
  response.headers['Content-Type'] = 'text/event-stream'
  response.headers['Cache-Control'] = 'no-cache'
  response.headers['X-Accel-Buffering'] = 'no'

  stream :keep_open do |out|
    # Send periodic heartbeat
    timer = EventMachine::PeriodicTimer.new(15) do
      out << ": heartbeat\n\n"
    end

    # Send updates
    on_task_update(task_id) do |update|
      out << "data: #{update.to_json}\n\n"
    end

    # Cleanup
    out.callback { timer.cancel }
  end
end
```

#### Issue 4: Memory Leaks with Large Files

**Problem**: Server memory growing with file transfers

**Solution**:
```ruby
# Use URIs instead of embedding bytes for large files
def create_file_artifact(file_path)
  # Instead of loading entire file into memory:
  # bytes = File.read(file_path)

  # Use a URI reference:
  file_url = upload_to_storage(file_path)

  A2A::Models::Artifact.new(
    name: "Large File",
    parts: [
      A2A::Models::FilePart.new(
        file: {
          name: File.basename(file_path),
          mime_type: detect_mime_type(file_path),
          uri: file_url
        }
      )
    ]
  )
end
```

#### Issue 5: Concurrent Task Processing

**Problem**: Race conditions with shared state

**Solution**:
```ruby
require 'concurrent-ruby'

class ThreadSafeTaskStore
  def initialize
    @tasks = Concurrent::Hash.new
    @locks = Concurrent::Hash.new
  end

  def update_task(task_id)
    lock = @locks.compute_if_absent(task_id) { Mutex.new }

    lock.synchronize do
      task = @tasks[task_id] or raise A2A::TaskNotFoundError
      updated = yield task
      @tasks[task_id] = updated
    end
  end
end
```

### Debugging Tips

#### Enable Verbose Logging

```ruby
require 'debug_me'

# Use debug_me for all debugging output
debug_me "Starting task processing"
debug_me { [ :task_id, :message, :session_id ] }

# For constant strings
debug_me "Task completed successfully"
```

#### Inspect JSON Payloads

```ruby
def log_request(request)
  debug_me "Incoming request:"
  debug_me JSON.pretty_generate(request.to_h)
end

def log_response(response)
  debug_me "Outgoing response:"
  debug_me JSON.pretty_generate(response.to_h)
end
```

#### Test with curl

```bash
# Test AgentCard endpoint
curl https://example.com/.well-known/agent.json

# Test task submission
curl -X POST https://example.com/a2a \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": "1",
    "method": "tasks/send",
    "params": {
      "taskId": "task-123",
      "message": {
        "role": "user",
        "parts": [{"type": "text", "text": "Hello"}]
      }
    }
  }'

# Test SSE streaming
curl -N https://example.com/a2a/stream/task-123
```

## Additional Resources

### Documentation

- [Basic Examples](basic.md) - Fundamental data model usage
- [Client Examples](client.md) - Building A2A HTTP clients
- [Server Examples](server.md) - Building A2A HTTP servers
- [Gem Architecture](../architecture/gem-architecture.md) - Gem architecture details
- [A2A Protocol Specification](../protocol-spec.md) - Full protocol spec

### External Links

- [A2A Protocol GitHub](https://github.com/anthropics/a2a)
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
- [Server-Sent Events (SSE)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
- [Faraday HTTP Client](https://lostisland.github.io/faraday/)
- [Sinatra Web Framework](http://sinatrarb.com/)

### Related Gems

- `faraday` - HTTP client library
- `sinatra` - Web application framework
- `puma` - Concurrent web server
- `debug_me` - Debugging utility

### Community

- [GitHub Issues](https://github.com/madbomber/a2a/issues)
- [Discussions](https://github.com/madbomber/a2a/discussions)

## Next Steps

Now that you understand the overview, proceed to:

1. **[Basic Examples](basic.md)** to learn the fundamental data models
2. **[Client Examples](client.md)** to build A2A clients
3. **[Server Examples](server.md)** to build A2A servers

Each guide contains complete, working code examples that you can copy and adapt for your own use.

---

[Back to Documentation Home](../index.md)
