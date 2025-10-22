# Streaming with Server-Sent Events (SSE)

Comprehensive guide to implementing real-time task updates using Server-Sent Events in the A2A protocol.

## Table of Contents

- [Overview](#overview)
- [When to Use Streaming](#when-to-use-streaming)
- [Architecture](#architecture)
- [Protocol Details](#protocol-details)
- [Implementation Guide](#implementation-guide)
  - [Server-Side Implementation](#server-side-implementation)
  - [Client-Side Implementation](#client-side-implementation)
- [Event Types](#event-types)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Complete Examples](#complete-examples)
- [Testing Strategies](#testing-strategies)
- [Troubleshooting](#troubleshooting)

## Overview

Streaming in A2A uses Server-Sent Events (SSE) to provide real-time updates for long-running tasks. Unlike traditional HTTP request-response patterns, SSE establishes a persistent connection that allows the server to push updates to the client as the task progresses.

### Why SSE?

SSE offers several advantages for agent communication:

- **Unidirectional**: Perfect for server-to-client updates
- **Simple**: Built on HTTP, no WebSocket complexity
- **Automatic Reconnection**: Browsers handle reconnection automatically
- **Event IDs**: Natural support for resuming interrupted streams
- **Text-Based**: Easy to debug and monitor

### Streaming Capability

Agents indicate streaming support in their AgentCard:

```ruby
require 'a2a'

agent_card = A2A::Models::AgentCard.new(
  name: "Streaming Agent",
  url: "https://api.example.com/a2a",
  version: "1.0.0",
  capabilities: {
    streaming: true,  # Indicates SSE support
    push_notifications: false,
    state_transition_history: false
  }
)
```

## When to Use Streaming

Streaming is ideal for:

1. **Long-Running Tasks**: Tasks that take more than a few seconds
2. **Progressive Results**: When partial results should be shown immediately
3. **Multi-Step Processes**: Tasks with distinct processing phases
4. **Real-Time Feedback**: When users need to see progress updates
5. **Interruptible Work**: Tasks that may require user input mid-execution

**Don't use streaming for**:
- Quick tasks (under 2 seconds)
- Simple request-response interactions
- Tasks with no intermediate state

## Architecture

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 600" style="background:transparent">
  <!-- Client -->
  <rect x="50" y="50" width="150" height="80" fill="#1e3a8a" stroke="#3b82f6" stroke-width="2" rx="5"/>
  <text x="125" y="95" text-anchor="middle" fill="#fff" font-family="Arial" font-size="16" font-weight="bold">A2A Client</text>

  <!-- Server -->
  <rect x="600" y="50" width="150" height="80" fill="#1e3a8a" stroke="#3b82f6" stroke-width="2" rx="5"/>
  <text x="675" y="95" text-anchor="middle" fill="#fff" font-family="Arial" font-size="16" font-weight="bold">A2A Server</text>

  <!-- Agent -->
  <rect x="600" y="470" width="150" height="80" fill="#064e3b" stroke="#10b981" stroke-width="2" rx="5"/>
  <text x="675" y="515" text-anchor="middle" fill="#fff" font-family="Arial" font-size="16" font-weight="bold">Agent Core</text>

  <!-- Request -->
  <line x1="200" y1="90" x2="590" y2="90" stroke="#3b82f6" stroke-width="2" marker-end="url(#arrowblue)"/>
  <text x="400" y="80" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12">POST tasks/sendSubscribe</text>

  <!-- SSE Connection -->
  <line x1="600" y1="130" x2="200" y2="130" stroke="#10b981" stroke-width="2" stroke-dasharray="5,5"/>
  <text x="400" y="120" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12">SSE Connection Established</text>

  <!-- Processing -->
  <line x1="675" y1="130" x2="675" y2="460" stroke="#f59e0b" stroke-width="2" marker-end="url(#arroworange)"/>
  <text x="705" y="295" fill="#fff" font-family="Arial" font-size="12">Processing</text>

  <!-- Events -->
  <line x1="590" y1="200" x2="210" y2="200" stroke="#8b5cf6" stroke-width="2" marker-end="url(#arrowpurple)"/>
  <text x="400" y="190" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12">TaskStatusUpdateEvent</text>

  <line x1="590" y1="280" x2="210" y2="280" stroke="#8b5cf6" stroke-width="2" marker-end="url(#arrowpurple)"/>
  <text x="400" y="270" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12">TaskArtifactUpdateEvent</text>

  <line x1="590" y1="360" x2="210" y2="360" stroke="#8b5cf6" stroke-width="2" marker-end="url(#arrowpurple)"/>
  <text x="400" y="350" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12">TaskStatusUpdateEvent (completed)</text>

  <!-- Connection Close -->
  <line x1="590" y1="440" x2="210" y2="440" stroke="#ef4444" stroke-width="2" stroke-dasharray="5,5"/>
  <text x="400" y="430" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12">Connection Closed</text>

  <!-- Arrow markers -->
  <defs>
    <marker id="arrowblue" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#3b82f6"/>
    </marker>
    <marker id="arrowgreen" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#10b981"/>
    </marker>
    <marker id="arroworange" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#f59e0b"/>
    </marker>
    <marker id="arrowpurple" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#8b5cf6"/>
    </marker>
  </defs>
</svg>
```

### Flow Description

1. **Client Initiates**: Sends `tasks/sendSubscribe` JSON-RPC request
2. **Server Establishes SSE**: Returns HTTP 200 with `Content-Type: text/event-stream`
3. **Agent Processes**: Performs work asynchronously
4. **Server Streams Events**: Sends `TaskStatusUpdateEvent` and `TaskArtifactUpdateEvent` as progress occurs
5. **Completion**: Final event with terminal state, connection closes

## Protocol Details

### JSON-RPC Method

Streaming uses the `tasks/sendSubscribe` method:

```json
{
  "jsonrpc": "2.0",
  "id": "req-123",
  "method": "tasks/sendSubscribe",
  "params": {
    "task": {
      "id": "task-456",
      "sessionId": "session-789",
      "status": {
        "state": "submitted",
        "timestamp": "2025-10-21T10:00:00Z"
      }
    },
    "message": {
      "role": "user",
      "parts": [
        {
          "text": "Generate a detailed market analysis report"
        }
      ]
    }
  }
}
```

### HTTP Response Headers

The server must set these headers for SSE:

```
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
X-Accel-Buffering: no
```

### SSE Event Format

Each event follows the SSE specification:

```
data: {"jsonrpc":"2.0","id":"req-123","result":{"type":"TaskStatusUpdateEvent","task":{...}}}

data: {"jsonrpc":"2.0","id":"req-123","result":{"type":"TaskArtifactUpdateEvent","taskId":"task-456","artifact":{...}}}

data: {"jsonrpc":"2.0","id":"req-123","result":{"type":"TaskStatusUpdateEvent","task":{"status":{"state":"completed"}}}}

```

## Implementation Guide

### Server-Side Implementation

#### Using Rack (Sinatra/Rails)

```ruby
require 'a2a'
require 'json'

class A2AStreamingServer < A2A::Server::Base
  # Handle streaming task submission
  def handle_send_task_streaming(params)
    task_data = params['task'] || params[:task]
    message_data = params['message'] || params[:message]

    task = A2A::Models::Task.from_hash(task_data)
    message = A2A::Models::Message.from_hash(message_data)

    # Return an Enumerator that yields SSE events
    Enumerator.new do |yielder|
      stream_task_execution(task, message, yielder)
    end
  end

  private

  def stream_task_execution(task, message, yielder)
    begin
      # Send initial "working" status
      task = update_task_status(task, 'working',
        "Starting analysis...")
      yield_task_status(task, yielder)

      # Simulate multi-step processing
      steps = [
        "Collecting market data...",
        "Analyzing trends...",
        "Generating visualizations...",
        "Compiling final report..."
      ]

      steps.each_with_index do |step_message, index|
        sleep(2) # Simulate work

        # Update status
        task = update_task_status(task, 'working', step_message)
        yield_task_status(task, yielder)

        # Generate intermediate artifacts
        if index == 1
          artifact = create_data_artifact(
            "Preliminary Analysis",
            { trends: ["upward", "volatile"], confidence: 0.75 }
          )
          yield_artifact_update(task.id, artifact, yielder)
        end
      end

      # Generate final artifact
      final_artifact = create_report_artifact(task.id)
      yield_artifact_update(task.id, final_artifact, yielder)

      # Complete the task
      task = update_task_status(task, 'completed', "Analysis complete")
      task.instance_variable_set(:@artifacts, [final_artifact])
      yield_task_status(task, yielder)

    rescue StandardError => e
      # Handle errors by sending failed status
      debug_me "Error in streaming: #{e.message}"
      task = update_task_status(task, 'failed', e.message)
      yield_task_status(task, yielder)
    ensure
      # Connection will close after final yield
    end
  end

  def yield_task_status(task, yielder)
    event = {
      jsonrpc: "2.0",
      id: task.id,
      result: {
        type: "TaskStatusUpdateEvent",
        task: task.to_h
      }
    }
    yielder << format_sse_event(event)
  end

  def yield_artifact_update(task_id, artifact, yielder)
    event = {
      jsonrpc: "2.0",
      id: task_id,
      result: {
        type: "TaskArtifactUpdateEvent",
        taskId: task_id,
        artifact: artifact.to_h
      }
    }
    yielder << format_sse_event(event)
  end

  def format_sse_event(data)
    "data: #{JSON.generate(data)}\n\n"
  end

  def update_task_status(task, state, message_text)
    A2A::Models::Task.new(
      id: task.id,
      session_id: task.session_id,
      status: {
        state: state,
        message: A2A::Models::Message.text(
          role: 'agent',
          text: message_text
        ),
        timestamp: Time.now.utc.iso8601
      },
      artifacts: task.artifacts,
      metadata: task.metadata
    )
  end

  def create_data_artifact(name, data)
    A2A::Models::Artifact.new(
      name: name,
      parts: [
        A2A::Models::DataPart.new(data: data)
      ],
      metadata: {
        generated_at: Time.now.utc.iso8601
      }
    )
  end

  def create_report_artifact(task_id)
    A2A::Models::Artifact.new(
      name: "Market Analysis Report",
      description: "Comprehensive market analysis with trends and predictions",
      parts: [
        A2A::Models::TextPart.new(
          text: "# Market Analysis Report\n\nDetailed analysis shows..."
        ),
        A2A::Models::DataPart.new(
          data: {
            summary: {
              market_trend: "bullish",
              risk_level: "moderate",
              confidence: 0.89
            },
            key_findings: [
              "Strong growth in technology sector",
              "Increased volatility in energy markets",
              "Emerging opportunities in healthcare"
            ],
            recommendations: [
              "Diversify portfolio across sectors",
              "Monitor regulatory changes",
              "Consider long-term positions"
            ]
          }
        )
      ],
      metadata: {
        task_id: task_id,
        generated_at: Time.now.utc.iso8601,
        format: "markdown+json"
      }
    )
  end
end
```

#### Sinatra Application

```ruby
require 'sinatra'
require 'sinatra/streaming'
require 'json'
require_relative 'a2a_streaming_server'

# Configure streaming
set :server, :puma
set :threaded, true

# Agent card endpoint
get '/.well-known/agent.json' do
  content_type :json

  agent_card = A2A::Models::AgentCard.new(
    name: "Market Analysis Agent",
    url: "#{request.base_url}/a2a",
    version: "1.0.0",
    description: "Provides detailed market analysis and insights",
    capabilities: {
      streaming: true,
      push_notifications: false,
      state_transition_history: false
    },
    skills: [
      {
        id: "market-analysis",
        name: "Market Analysis",
        description: "Analyze market trends and generate reports",
        tags: ["finance", "analysis", "reporting"]
      }
    ]
  )

  JSON.generate(agent_card.to_h)
end

# A2A endpoint with streaming
post '/a2a' do
  request_body = JSON.parse(request.body.read)

  # Parse JSON-RPC request
  method_name = request_body['method']
  params = request_body['params']
  request_id = request_body['id']

  server = A2AStreamingServer.new(nil)

  case method_name
  when 'tasks/sendSubscribe'
    # Set SSE headers
    content_type 'text/event-stream'
    headers 'Cache-Control' => 'no-cache',
            'Connection' => 'keep-alive',
            'X-Accel-Buffering' => 'no'

    # Stream events
    stream :keep_open do |out|
      begin
        event_enum = server.handle_send_task_streaming(params)

        event_enum.each do |sse_data|
          out << sse_data
        end
      ensure
        out.close
      end
    end

  when 'tasks/send'
    # Non-streaming task handling
    content_type :json
    task = server.handle_send_task(params)

    response = {
      jsonrpc: "2.0",
      id: request_id,
      result: task.to_h
    }

    JSON.generate(response)

  else
    status 400
    content_type :json

    error_response = {
      jsonrpc: "2.0",
      id: request_id,
      error: {
        code: -32601,
        message: "Method not found"
      }
    }

    JSON.generate(error_response)
  end
end
```

### Client-Side Implementation

#### Basic Streaming Client

```ruby
require 'a2a'
require 'http'
require 'json'

class A2AStreamingClient < A2A::Client::Base
  def initialize(agent_url)
    super(agent_url)
    @http_client = HTTP.timeout(connect: 5, read: 300)
  end

  def send_task_streaming(task_id:, message:, session_id: nil, &block)
    raise ArgumentError, "Block required for streaming" unless block_given?

    # Build the request
    request = build_streaming_request(task_id, message, session_id)

    # Make SSE request
    response = @http_client.post(
      agent_url,
      json: request,
      headers: {
        'Accept' => 'text/event-stream'
      }
    )

    unless response.status.success?
      raise A2A::InternalError, "HTTP #{response.status}: #{response.body}"
    end

    # Parse SSE stream
    parse_sse_stream(response.body, &block)
  end

  private

  def build_streaming_request(task_id, message, session_id)
    task = A2A::Models::Task.new(
      id: task_id,
      session_id: session_id,
      status: {
        state: 'submitted',
        timestamp: Time.now.utc.iso8601
      }
    )

    {
      jsonrpc: "2.0",
      id: task_id,
      method: "tasks/sendSubscribe",
      params: {
        task: task.to_h,
        message: message.to_h
      }
    }
  end

  def parse_sse_stream(body_enum, &block)
    buffer = ""

    body_enum.each do |chunk|
      buffer << chunk

      # Process complete events
      while buffer.include?("\n\n")
        event_data, buffer = buffer.split("\n\n", 2)

        # Parse SSE event
        if event_data.start_with?("data: ")
          json_data = event_data.sub(/^data: /, '').strip
          next if json_data.empty?

          begin
            event = JSON.parse(json_data, symbolize_names: true)
            process_event(event, &block)
          rescue JSON::ParserError => e
            debug_me "Failed to parse SSE event: #{e.message}"
          end
        end
      end
    end
  end

  def process_event(event)
    return unless event[:result]

    result = event[:result]
    event_type = result[:type]

    case event_type
    when 'TaskStatusUpdateEvent'
      task = A2A::Models::Task.from_hash(result[:task])
      yield :status, task

    when 'TaskArtifactUpdateEvent'
      task_id = result[:taskId]
      artifact = A2A::Models::Artifact.from_hash(result[:artifact])
      yield :artifact, task_id, artifact

    else
      debug_me "Unknown event type: #{event_type}"
    end
  end
end
```

#### Using the Streaming Client

```ruby
require_relative 'a2a_streaming_client'

client = A2AStreamingClient.new('https://api.example.com/a2a')

message = A2A::Models::Message.text(
  role: 'user',
  text: 'Analyze the current state of the technology sector'
)

task_id = "task-#{SecureRandom.uuid}"
artifacts = []
final_task = nil

begin
  client.send_task_streaming(
    task_id: task_id,
    message: message,
    session_id: "session-#{SecureRandom.uuid}"
  ) do |event_type, *args|
    case event_type
    when :status
      task = args[0]
      debug_me "Status: #{task.status.state.value}"

      if task.status.message
        debug_me "Message: #{task.status.message.parts.first&.text}"
      end

      final_task = task

      # Break if terminal state
      break if task.status.state.terminal?

    when :artifact
      task_id, artifact = args
      debug_me "Received artifact: #{artifact.name}"
      artifacts << artifact

      # Display artifact content
      artifact.parts.each do |part|
        case part
        when A2A::Models::TextPart
          debug_me "Text: #{part.text[0..100]}..."
        when A2A::Models::DataPart
          debug_me "Data: #{part.data.inspect}"
        end
      end
    end
  end

  debug_me "Task completed with #{artifacts.size} artifacts"

rescue StandardError => e
  debug_me "Streaming error: #{e.message}"
end
```

## Event Types

### TaskStatusUpdateEvent

Sent when task status changes:

```ruby
# Server sends:
{
  jsonrpc: "2.0",
  id: "task-123",
  result: {
    type: "TaskStatusUpdateEvent",
    task: {
      id: "task-123",
      sessionId: "session-456",
      status: {
        state: "working",
        message: {
          role: "agent",
          parts: [
            { text: "Processing data..." }
          ]
        },
        timestamp: "2025-10-21T10:05:30Z"
      }
    }
  }
}
```

**When to send**:
- Task state transitions (submitted → working → completed)
- Progress updates during long operations
- Error conditions (→ failed)
- User input required (→ input-required)

### TaskArtifactUpdateEvent

Sent when artifacts are generated:

```ruby
# Server sends:
{
  jsonrpc: "2.0",
  id: "task-123",
  result: {
    type: "TaskArtifactUpdateEvent",
    taskId: "task-123",
    artifact: {
      name: "Intermediate Results",
      description: "Partial analysis results",
      parts: [
        {
          data: {
            processed_records: 1000,
            estimated_completion: "70%"
          }
        }
      ]
    }
  }
}
```

**When to send**:
- Partial results become available
- Progressive output (e.g., streaming text generation)
- Intermediate files generated
- Multi-artifact tasks (charts, tables, reports)

## Error Handling

### Connection Errors

```ruby
def send_task_streaming_with_retry(task_id:, message:, max_retries: 3)
  retries = 0

  begin
    send_task_streaming(task_id: task_id, message: message) do |event_type, *args|
      yield event_type, *args
    end

  rescue HTTP::TimeoutError, HTTP::ConnectionError => e
    retries += 1

    if retries <= max_retries
      debug_me "Connection error, retrying (#{retries}/#{max_retries})..."
      sleep(2 ** retries) # Exponential backoff
      retry
    else
      raise A2A::InternalError, "Max retries exceeded: #{e.message}"
    end
  end
end
```

### Server-Side Error Events

```ruby
def stream_with_error_handling(task, message, yielder)
  begin
    # Processing logic
    process_task(task, message, yielder)

  rescue ValidationError => e
    # Send error status update
    error_task = A2A::Models::Task.new(
      id: task.id,
      session_id: task.session_id,
      status: {
        state: 'failed',
        message: A2A::Models::Message.text(
          role: 'agent',
          text: "Validation failed: #{e.message}"
        ),
        timestamp: Time.now.utc.iso8601
      }
    )

    yield_task_status(error_task, yielder)

  rescue StandardError => e
    debug_me "Unexpected error: #{e.message}"
    debug_me e.backtrace.join("\n")

    # Send generic error
    error_task = A2A::Models::Task.new(
      id: task.id,
      session_id: task.session_id,
      status: {
        state: 'failed',
        message: A2A::Models::Message.text(
          role: 'agent',
          text: "An error occurred while processing your request"
        ),
        timestamp: Time.now.utc.iso8601
      }
    )

    yield_task_status(error_task, yielder)
  end
end
```

### Client-Side Timeout Handling

```ruby
class StreamingTimeout < StandardError; end

def send_task_streaming_with_timeout(task_id:, message:, timeout: 300)
  start_time = Time.now

  send_task_streaming(task_id: task_id, message: message) do |event_type, *args|
    # Check timeout
    elapsed = Time.now - start_time
    if elapsed > timeout
      raise StreamingTimeout, "Streaming exceeded #{timeout}s timeout"
    end

    yield event_type, *args
  end
end
```

## Best Practices

### 1. Send Frequent Status Updates

Keep clients informed of progress:

```ruby
def process_large_dataset(task, data, yielder)
  total = data.size
  batch_size = 100

  data.each_slice(batch_size).with_index do |batch, index|
    # Process batch
    results = process_batch(batch)

    # Update progress every batch
    progress = ((index + 1) * batch_size * 100.0 / total).round(1)
    task = update_task_status(
      task,
      'working',
      "Processing: #{progress}% complete (#{(index + 1) * batch_size}/#{total})"
    )
    yield_task_status(task, yielder)
  end
end
```

### 2. Use Meaningful Event Timing

Don't spam events - batch updates when appropriate:

```ruby
def stream_with_throttling(task, yielder)
  last_update = Time.now
  min_interval = 1.0 # Minimum 1 second between updates

  loop do
    work_result = do_some_work

    # Only send update if enough time has passed
    if Time.now - last_update >= min_interval
      task = update_task_status(task, 'working', work_result.message)
      yield_task_status(task, yielder)
      last_update = Time.now
    end

    break if work_complete?
  end
end
```

### 3. Always Send Terminal State

Ensure clients know when the task is complete:

```ruby
def stream_task(task, message, yielder)
  begin
    # Processing
    process_work(task, message, yielder)

  ensure
    # Always send final status
    unless task.status.state.terminal?
      final_task = update_task_status(task, 'completed', "Processing complete")
      yield_task_status(final_task, yielder)
    end
  end
end
```

### 4. Include Event IDs for Resumability

Add event IDs to support reconnection:

```ruby
def format_sse_event_with_id(data, event_id)
  <<~SSE
    id: #{event_id}
    data: #{JSON.generate(data)}

  SSE
end

def stream_with_event_ids(task, yielder)
  event_counter = 0

  loop do
    event_counter += 1

    # Generate event
    event_data = create_status_event(task)

    # Send with ID
    yielder << format_sse_event_with_id(event_data, event_counter)

    break if task.status.state.terminal?
  end
end
```

### 5. Implement Keep-Alive

Prevent connection timeouts with periodic pings:

```ruby
def stream_with_keepalive(task, message, yielder)
  last_event = Time.now
  keepalive_interval = 30 # seconds

  processing_thread = Thread.new do
    process_task(task, message, yielder)
  end

  until processing_thread.join(1)
    # Send comment as keep-alive if no recent events
    if Time.now - last_event > keepalive_interval
      yielder << ": keepalive\n\n"
      last_event = Time.now
    end
  end
end
```

## Complete Examples

### Multi-Step Document Processing

```ruby
class DocumentProcessingServer < A2A::Server::Base
  def handle_send_task_streaming(params)
    task = A2A::Models::Task.from_hash(params['task'])
    message = A2A::Models::Message.from_hash(params['message'])

    Enumerator.new do |yielder|
      stream_document_processing(task, message, yielder)
    end
  end

  private

  def stream_document_processing(task, message, yielder)
    # Extract document from message
    document_part = message.parts.find { |p| p.is_a?(A2A::Models::FilePart) }

    unless document_part
      fail_task(task, "No document provided", yielder)
      return
    end

    # Step 1: Extract text
    update_and_yield(task, 'working', "Extracting text from document...", yielder)
    text_content = extract_text(document_part)

    # Step 2: Analyze content
    update_and_yield(task, 'working', "Analyzing document structure...", yielder)
    structure = analyze_structure(text_content)

    # Send intermediate artifact
    structure_artifact = A2A::Models::Artifact.new(
      name: "Document Structure",
      parts: [A2A::Models::DataPart.new(data: structure)]
    )
    yield_artifact_update(task.id, structure_artifact, yielder)

    # Step 3: Extract entities
    update_and_yield(task, 'working', "Extracting entities...", yielder)
    entities = extract_entities(text_content)

    # Step 4: Generate summary
    update_and_yield(task, 'working', "Generating summary...", yielder)
    summary = generate_summary(text_content)

    # Send final artifacts
    summary_artifact = A2A::Models::Artifact.new(
      name: "Document Summary",
      parts: [
        A2A::Models::TextPart.new(text: summary),
        A2A::Models::DataPart.new(data: {
          entities: entities,
          word_count: text_content.split.size,
          structure: structure
        })
      ]
    )

    yield_artifact_update(task.id, summary_artifact, yielder)

    # Complete
    task.instance_variable_set(:@artifacts, [structure_artifact, summary_artifact])
    update_and_yield(task, 'completed', "Document processing complete", yielder)
  end

  def update_and_yield(task, state, message_text, yielder)
    task = update_task_status(task, state, message_text)
    yield_task_status(task, yielder)
    task
  end

  def fail_task(task, error_message, yielder)
    task = update_task_status(task, 'failed', error_message)
    yield_task_status(task, yielder)
  end

  def extract_text(file_part)
    # Simulate text extraction
    "Sample document content..."
  end

  def analyze_structure(text)
    { sections: 5, paragraphs: 23, headings: 8 }
  end

  def extract_entities(text)
    ["Company A", "Product B", "Location C"]
  end

  def generate_summary(text)
    "This document discusses..."
  end
end
```

### Real-Time Data Analysis Client

```ruby
class AnalysisClient
  def initialize(agent_url)
    @client = A2AStreamingClient.new(agent_url)
    @progress_bar = nil
  end

  def analyze_dataset(dataset_file)
    message = create_analysis_message(dataset_file)
    task_id = "analysis-#{SecureRandom.uuid}"

    artifacts = []
    status_messages = []

    debug_me "Starting analysis..."

    @client.send_task_streaming(
      task_id: task_id,
      message: message
    ) do |event_type, *args|
      case event_type
      when :status
        task = args[0]
        handle_status_update(task, status_messages)

      when :artifact
        _, artifact = args
        artifacts << artifact
        handle_artifact(artifact)
      end
    end

    debug_me "\nAnalysis complete!"
    debug_me "Received #{artifacts.size} artifacts"

    artifacts
  end

  private

  def create_analysis_message(file_path)
    file_content = File.binread(file_path)

    A2A::Models::Message.new(
      role: 'user',
      parts: [
        A2A::Models::TextPart.new(
          text: "Analyze this dataset and provide insights"
        ),
        A2A::Models::FilePart.new(
          file: {
            name: File.basename(file_path),
            mime_type: 'text/csv',
            bytes: Base64.strict_encode64(file_content)
          }
        )
      ]
    )
  end

  def handle_status_update(task, status_messages)
    state = task.status.state.value

    if task.status.message
      msg = task.status.message.parts.first&.text
      status_messages << msg if msg

      # Show progress
      debug_me "[#{state.upcase}] #{msg}"

      # Parse percentage if present
      if msg =~ /(\d+)%/
        update_progress_bar($1.to_i)
      end
    end
  end

  def handle_artifact(artifact)
    debug_me "\nReceived: #{artifact.name}"

    artifact.parts.each do |part|
      case part
      when A2A::Models::DataPart
        # Display key metrics
        if part.data[:summary]
          debug_me "Summary: #{part.data[:summary].inspect}"
        end

      when A2A::Models::FilePart
        # Save file artifacts
        if part.file[:bytes]
          save_artifact_file(artifact.name, part.file[:bytes])
        end
      end
    end
  end

  def update_progress_bar(percentage)
    # Visual progress indicator
    bar_width = 50
    filled = (bar_width * percentage / 100.0).round
    bar = "#{'=' * filled}#{' ' * (bar_width - filled)}"
    print "\r[#{bar}] #{percentage}%"
  end

  def save_artifact_file(name, base64_bytes)
    filename = "output/#{name.gsub(/\s+/, '_')}"
    File.write(filename, Base64.decode64(base64_bytes))
    debug_me "Saved: #{filename}"
  end
end
```

## Testing Strategies

### Unit Testing Server Streaming

```ruby
require 'rspec'

RSpec.describe A2AStreamingServer do
  let(:server) { described_class.new(agent_card) }
  let(:agent_card) { build_agent_card }

  describe '#handle_send_task_streaming' do
    it 'yields multiple status events' do
      task = build_task
      message = build_message
      params = { task: task.to_h, message: message.to_h }

      events = []
      enum = server.handle_send_task_streaming(params)

      enum.each do |event_data|
        # Parse SSE format
        json_str = event_data.sub(/^data: /, '').strip
        events << JSON.parse(json_str, symbolize_names: true)
      end

      expect(events.size).to be > 1
      expect(events.first[:result][:type]).to eq('TaskStatusUpdateEvent')
    end

    it 'sends terminal state as final event' do
      params = { task: build_task.to_h, message: build_message.to_h }
      enum = server.handle_send_task_streaming(params)

      final_event = nil
      enum.each do |event_data|
        json_str = event_data.sub(/^data: /, '').strip
        final_event = JSON.parse(json_str, symbolize_names: true)
      end

      task_state = final_event[:result][:task][:status][:state]
      expect(['completed', 'failed', 'canceled']).to include(task_state)
    end

    it 'yields artifact events when artifacts generated' do
      params = { task: build_task.to_h, message: build_message.to_h }
      enum = server.handle_send_task_streaming(params)

      artifact_events = enum.map do |event_data|
        json_str = event_data.sub(/^data: /, '').strip
        JSON.parse(json_str, symbolize_names: true)
      end.select { |e| e[:result][:type] == 'TaskArtifactUpdateEvent' }

      expect(artifact_events.size).to be > 0
    end
  end
end
```

### Integration Testing with Mock SSE

```ruby
require 'webmock/rspec'

RSpec.describe A2AStreamingClient do
  let(:client) { described_class.new('https://api.test/a2a') }

  describe '#send_task_streaming' do
    it 'processes SSE events correctly' do
      # Mock SSE response
      sse_body = <<~SSE
        data: {"jsonrpc":"2.0","id":"task-1","result":{"type":"TaskStatusUpdateEvent","task":{"id":"task-1","status":{"state":"working"}}}}

        data: {"jsonrpc":"2.0","id":"task-1","result":{"type":"TaskArtifactUpdateEvent","taskId":"task-1","artifact":{"name":"Test"}}}

        data: {"jsonrpc":"2.0","id":"task-1","result":{"type":"TaskStatusUpdateEvent","task":{"id":"task-1","status":{"state":"completed"}}}}

      SSE

      stub_request(:post, 'https://api.test/a2a')
        .to_return(
          status: 200,
          body: sse_body,
          headers: { 'Content-Type' => 'text/event-stream' }
        )

      events = []
      message = A2A::Models::Message.text(role: 'user', text: 'test')

      client.send_task_streaming(
        task_id: 'task-1',
        message: message
      ) do |event_type, *args|
        events << [event_type, args]
      end

      expect(events.size).to eq(3)
      expect(events[0][0]).to eq(:status)
      expect(events[1][0]).to eq(:artifact)
      expect(events[2][0]).to eq(:status)
    end
  end
end
```

## Troubleshooting

### Issue: Connection Drops Unexpectedly

**Symptoms**: SSE connection closes before task completes

**Solutions**:
1. Implement keep-alive comments
2. Check for proxy timeouts (nginx, CloudFlare)
3. Verify server doesn't buffer responses
4. Add connection monitoring

```ruby
# Server-side keep-alive
def stream_with_monitoring(task, yielder)
  Thread.new do
    loop do
      sleep(30)
      yielder << ": ping\n\n"
    end
  end

  # Main processing
  process_task(task, yielder)
end
```

### Issue: Events Not Received in Real-Time

**Symptoms**: Events arrive in batches instead of streaming

**Solutions**:
1. Disable response buffering
2. Flush output after each event
3. Check reverse proxy configuration

```ruby
# Sinatra - disable buffering
set :stream, true

# Nginx configuration
# proxy_buffering off;
# proxy_cache off;
```

### Issue: Memory Leaks in Long Streams

**Symptoms**: Server memory grows during long tasks

**Solutions**:
1. Stream large data in chunks
2. Don't accumulate events in memory
3. Clean up resources after each event

```ruby
def stream_efficiently(task, yielder)
  # Don't do this - accumulates in memory
  # all_events = []
  # process.each { |e| all_events << e }
  # all_events.each { |e| yielder << e }

  # Do this instead - stream directly
  process_data do |event|
    yielder << format_sse_event(event)
    # Event is garbage collected after yield
  end
end
```

### Issue: Client Can't Reconnect After Disconnect

**Symptoms**: Lost connection requires full restart

**Solutions**:
1. Implement event IDs
2. Use `tasks/resubscribe` method
3. Store last event ID client-side

```ruby
class ResilientClient
  def stream_with_resume(task_id, message)
    last_event_id = nil

    begin
      send_task_streaming(task_id: task_id, message: message) do |event_type, *args|
        yield event_type, *args
        # Track last event (if server sends IDs)
        last_event_id = extract_event_id(args)
      end

    rescue ConnectionError => e
      debug_me "Connection lost, attempting resume..."
      # Use resubscribe with last event ID
      resubscribe(task_id, last_event_id) do |event_type, *args|
        yield event_type, *args
      end
    end
  end
end
```

---

## Related Documentation

- [Push Notifications](push-notifications.md) - Alternative to streaming for long tasks
- [Multi-Turn Conversations](conversations.md) - Using sessions with streaming
- [Error Handling](../guides/errors.md) - Comprehensive error handling guide
- [Task Lifecycle](../guides/tasks.md) - Understanding task states

## Further Reading

- [Server-Sent Events Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)
- [A2A Protocol Specification](../protocol-spec.md)
- [JSON-RPC 2.0](https://www.jsonrpc.org/specification)
