# Push Notifications with Webhooks

Comprehensive guide to implementing asynchronous task updates using webhook-based push notifications in the A2A protocol.

## Table of Contents

- [Overview](#overview)
- [When to Use Push Notifications](#when-to-use-push-notifications)
- [Architecture](#architecture)
- [Protocol Details](#protocol-details)
- [Implementation Guide](#implementation-guide)
  - [Server-Side Implementation](#server-side-implementation)
  - [Client-Side Webhook Receiver](#client-side-webhook-receiver)
- [Security](#security)
- [Retry Logic](#retry-logic)
- [Best Practices](#best-practices)
- [Complete Examples](#complete-examples)
- [Testing Strategies](#testing-strategies)
- [Troubleshooting](#troubleshooting)

## Overview

Push notifications enable agents to proactively send task updates to clients via HTTP webhooks. Instead of clients polling for updates or maintaining an open SSE connection, the server pushes updates to a client-specified webhook URL whenever task state changes.

### Push Notifications vs Streaming

| Feature | Push Notifications | Streaming (SSE) |
|---------|-------------------|-----------------|
| Connection | Stateless webhooks | Persistent connection |
| Use Case | Long-running background tasks | Real-time interactive tasks |
| Reliability | Retry logic required | Automatic reconnection |
| Scalability | Highly scalable | Limited by concurrent connections |
| Latency | Slightly higher | Minimal |
| Complexity | Higher (webhook security) | Lower |

### Push Notification Capability

Agents indicate push notification support in their AgentCard:

```ruby
require 'a2a'

agent_card = A2A::Models::AgentCard.new(
  name: "Background Processing Agent",
  url: "https://api.example.com/a2a",
  version: "1.0.0",
  capabilities: {
    streaming: false,
    push_notifications: true,  # Indicates webhook support
    state_transition_history: false
  }
)
```

## When to Use Push Notifications

Push notifications are ideal for:

1. **Long-Running Background Tasks**: Tasks that take minutes to hours
2. **Batch Processing**: Processing large datasets asynchronously
3. **Scheduled Jobs**: Tasks that run at specific times
4. **Resource-Intensive Operations**: Video encoding, large file processing
5. **Distributed Systems**: When client may not be continuously connected
6. **Mobile/Offline Clients**: Clients that aren't always online

**Don't use push notifications for**:
- Quick synchronous tasks (use regular `tasks/send`)
- Real-time interactive conversations (use streaming)
- When immediate response is required

## Architecture

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 700" style="background:transparent">
  <!-- Client -->
  <rect x="50" y="50" width="150" height="80" fill="#1e3a8a" stroke="#3b82f6" stroke-width="2" rx="5"/>
  <text x="125" y="95" text-anchor="middle" fill="#fff" font-family="Arial" font-size="16" font-weight="bold">A2A Client</text>

  <!-- Webhook Endpoint -->
  <rect x="50" y="250" width="150" height="80" fill="#7c3aed" stroke="#a78bfa" stroke-width="2" rx="5"/>
  <text x="125" y="285" text-anchor="middle" fill="#fff" font-family="Arial" font-size="14" font-weight="bold">Client Webhook</text>
  <text x="125" y="305" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12">Receiver</text>

  <!-- Server -->
  <rect x="700" y="50" width="150" height="80" fill="#1e3a8a" stroke="#3b82f6" stroke-width="2" rx="5"/>
  <text x="775" y="95" text-anchor="middle" fill="#fff" font-family="Arial" font-size="16" font-weight="bold">A2A Server</text>

  <!-- Agent -->
  <rect x="700" y="550" width="150" height="80" fill="#064e3b" stroke="#10b981" stroke-width="2" rx="5"/>
  <text x="775" y="595" text-anchor="middle" fill="#fff" font-family="Arial" font-size="16" font-weight="bold">Agent Core</text>

  <!-- Notification Queue -->
  <rect x="700" y="250" width="150" height="80" fill="#b45309" stroke="#f59e0b" stroke-width="2" rx="5"/>
  <text x="775" y="285" text-anchor="middle" fill="#fff" font-family="Arial" font-size="14" font-weight="bold">Notification</text>
  <text x="775" y="305" text-anchor="middle" fill="#fff" font-family="Arial" font-size="14" font-weight="bold">Queue</text>

  <!-- Step 1: Send Task -->
  <line x1="200" y1="90" x2="690" y2="90" stroke="#3b82f6" stroke-width="2" marker-end="url(#arrowblue)"/>
  <text x="445" y="75" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">1. POST tasks/send</text>

  <!-- Step 2: Set Push Config -->
  <line x1="200" y1="110" x2="690" y2="110" stroke="#a78bfa" stroke-width="2" marker-end="url(#arrowpurple)"/>
  <text x="445" y="125" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">2. tasks/pushNotification/set</text>

  <!-- Step 3: Immediate Response -->
  <line x1="690" y1="140" x2="210" y2="140" stroke="#10b981" stroke-width="2" stroke-dasharray="5,5"/>
  <text x="445" y="155" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">3. Response (task accepted)</text>

  <!-- Step 4: Processing -->
  <line x1="775" y1="130" x2="775" y2="540" stroke="#f59e0b" stroke-width="2" marker-end="url(#arroworange)"/>
  <text x="805" y="335" fill="#fff" font-family="Arial" font-size="11">4. Process</text>

  <!-- Step 5: Queue Updates -->
  <line x1="775" y1="330" x2="775" y2="250" stroke="#f59e0b" stroke-width="2" marker-end="url(#arroworange)" stroke-dasharray="5,5"/>
  <text x="805" y="290" fill="#fff" font-family="Arial" font-size="11">5. Enqueue</text>

  <!-- Step 6: Push Update -->
  <line x1="690" y1="290" x2="210" y2="290" stroke="#ef4444" stroke-width="3" marker-end="url(#arrowred)"/>
  <text x="445" y="275" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">6. POST webhook (status update)</text>

  <!-- Step 7: Another Update -->
  <line x1="690" y1="315" x2="210" y2="315" stroke="#ef4444" stroke-width="3" marker-end="url(#arrowred)"/>
  <text x="445" y="340" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">7. POST webhook (artifact update)</text>

  <!-- Step 8: Completion -->
  <line x1="690" y1="350" x2="210" y2="350" stroke="#ef4444" stroke-width="3" marker-end="url(#arrowred)"/>
  <text x="445" y="365" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">8. POST webhook (completed)</text>

  <!-- Client queries final state -->
  <line x1="200" y1="400" x2="690" y2="400" stroke="#3b82f6" stroke-width="2" stroke-dasharray="5,5" marker-end="url(#arrowblue)"/>
  <text x="445" y="415" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">9. tasks/get (optional)</text>

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
      <path d="M0,0 L0,6 L9,3 z" fill="#a78bfa"/>
    </marker>
    <marker id="arrowred" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#ef4444"/>
    </marker>
  </defs>
</svg>
```

### Flow Description

1. **Client Initiates**: Sends `tasks/send` to submit task
2. **Configure Webhook**: Calls `tasks/pushNotification/set` with webhook URL
3. **Immediate Response**: Server returns accepted task
4. **Async Processing**: Agent processes task in background
5. **Queue Updates**: Server queues notification events
6-8. **Push Updates**: Server POSTs updates to client webhook
9. **Optional Query**: Client can query final state with `tasks/get`

## Protocol Details

### Setting Push Notification Configuration

```json
{
  "jsonrpc": "2.0",
  "id": "req-456",
  "method": "tasks/pushNotification/set",
  "params": {
    "taskId": "task-123",
    "config": {
      "url": "https://client.example.com/webhooks/a2a",
      "token": "secret_webhook_token_12345",
      "authentication": {
        "type": "bearer",
        "credentials": {
          "token": "client_auth_token"
        }
      }
    }
  }
}
```

### Push Notification Payload

The server POSTs this to the client's webhook URL:

```json
{
  "taskId": "task-123",
  "event": {
    "type": "TaskStatusUpdateEvent",
    "task": {
      "id": "task-123",
      "status": {
        "state": "working",
        "message": {
          "role": "agent",
          "parts": [
            { "text": "Processing 50% complete..." }
          ]
        },
        "timestamp": "2025-10-21T10:30:00Z"
      }
    }
  }
}
```

Or for artifact updates:

```json
{
  "taskId": "task-123",
  "event": {
    "type": "TaskArtifactUpdateEvent",
    "taskId": "task-123",
    "artifact": {
      "name": "Intermediate Results",
      "parts": [
        {
          "data": {
            "processed": 5000,
            "total": 10000
          }
        }
      ]
    }
  }
}
```

## Implementation Guide

### Server-Side Implementation

#### Push Notification Manager

```ruby
require 'a2a'
require 'http'
require 'json'

class PushNotificationManager
  def initialize
    @configurations = {} # taskId => config
    @retry_queue = Queue.new
    @worker_thread = start_worker
  end

  # Store push notification configuration
  def set_config(task_id, config)
    validate_config!(config)

    @configurations[task_id] = A2A::Models::PushNotificationConfig.from_hash(config)

    debug_me "Push notification configured for task #{task_id}"
  end

  # Get push notification configuration
  def get_config(task_id)
    @configurations[task_id]
  end

  # Remove configuration when task completes
  def remove_config(task_id)
    @configurations.delete(task_id)
  end

  # Send task status update notification
  def notify_status_update(task)
    config = @configurations[task.id]
    return unless config

    event = {
      taskId: task.id,
      event: {
        type: 'TaskStatusUpdateEvent',
        task: task.to_h
      }
    }

    send_notification(config, event)
  end

  # Send task artifact update notification
  def notify_artifact_update(task_id, artifact)
    config = @configurations[task_id]
    return unless config

    event = {
      taskId: task_id,
      event: {
        type: 'TaskArtifactUpdateEvent',
        taskId: task_id,
        artifact: artifact.to_h
      }
    }

    send_notification(config, event)
  end

  private

  def validate_config!(config)
    raise ArgumentError, "URL is required" unless config[:url] || config['url']

    url = config[:url] || config['url']
    uri = URI.parse(url)

    raise ArgumentError, "URL must use HTTPS" unless uri.scheme == 'https'
    raise ArgumentError, "URL must have a host" unless uri.host
  rescue URI::InvalidURIError => e
    raise ArgumentError, "Invalid URL: #{e.message}"
  end

  def send_notification(config, event, attempt: 1)
    max_attempts = 5

    begin
      debug_me "Sending push notification (attempt #{attempt})"

      response = build_http_client(config).post(
        config.url,
        json: event,
        headers: build_headers(config)
      )

      if response.status.success?
        debug_me "Push notification delivered successfully"
      else
        handle_failed_delivery(config, event, attempt, response)
      end

    rescue HTTP::Error, Errno::ECONNREFUSED => e
      debug_me "Push notification failed: #{e.message}"
      handle_failed_delivery(config, event, attempt, nil)
    end
  end

  def build_http_client(config)
    HTTP.timeout(
      connect: 5,
      write: 10,
      read: 10
    )
  end

  def build_headers(config)
    headers = {
      'Content-Type' => 'application/json',
      'User-Agent' => 'A2A-Server/1.0'
    }

    # Add authentication if configured
    if config.authentication
      case config.authentication['type'] || config.authentication[:type]
      when 'bearer'
        token = config.authentication.dig('credentials', 'token') ||
                config.authentication.dig(:credentials, :token)
        headers['Authorization'] = "Bearer #{token}"
      end
    end

    # Add webhook verification token
    if config.token
      headers['X-Webhook-Token'] = config.token
    end

    headers
  end

  def handle_failed_delivery(config, event, attempt, response)
    max_attempts = 5

    if attempt < max_attempts
      # Exponential backoff: 2s, 4s, 8s, 16s, 32s
      delay = 2 ** attempt

      debug_me "Retrying in #{delay} seconds..."

      Thread.new do
        sleep(delay)
        send_notification(config, event, attempt: attempt + 1)
      end
    else
      debug_me "Push notification failed after #{max_attempts} attempts"
      # Could store in dead letter queue for manual review
    end
  end

  def start_worker
    # Background worker for processing retry queue
    Thread.new do
      loop do
        begin
          # Process retry queue
          sleep(1)
        rescue StandardError => e
          debug_me "Worker error: #{e.message}"
        end
      end
    end
  end
end
```

#### Server Integration

```ruby
require 'a2a'

class A2APushServer < A2A::Server::Base
  def initialize(agent_card)
    super(agent_card)
    @push_manager = PushNotificationManager.new
    @task_store = {} # Simple in-memory store
  end

  def handle_send_task(params)
    task = A2A::Models::Task.from_hash(params['task'] || params[:task])
    message = A2A::Models::Message.from_hash(params['message'] || params[:message])

    # Store task
    @task_store[task.id] = task

    # Process asynchronously
    Thread.new do
      process_task_async(task, message)
    end

    # Return immediately with submitted state
    task
  end

  def handle_set_push_notification(params)
    task_id = params['taskId'] || params[:taskId]
    config = params['config'] || params[:config]

    unless @task_store[task_id]
      raise A2A::TaskNotFoundError, "Task #{task_id} not found"
    end

    @push_manager.set_config(task_id, config)

    # Return success (no specific response defined in spec)
    nil
  end

  def handle_get_push_notification(params)
    task_id = params['taskId'] || params[:taskId]

    unless @task_store[task_id]
      raise A2A::TaskNotFoundError, "Task #{task_id} not found"
    end

    config = @push_manager.get_config(task_id)

    unless config
      raise A2A::UnsupportedOperationError, "No push notification configured for task"
    end

    config
  end

  private

  def process_task_async(task, message)
    begin
      # Update to working
      task = update_task(task, 'working', "Starting processing...")
      @push_manager.notify_status_update(task)

      # Simulate multi-step processing
      steps = [
        { progress: 25, message: "Phase 1: Data collection..." },
        { progress: 50, message: "Phase 2: Analysis..." },
        { progress: 75, message: "Phase 3: Report generation..." },
        { progress: 100, message: "Phase 4: Finalization..." }
      ]

      steps.each do |step|
        sleep(5) # Simulate work

        task = update_task(task, 'working', step[:message])
        @push_manager.notify_status_update(task)

        # Send intermediate artifact at 50%
        if step[:progress] == 50
          artifact = create_intermediate_artifact(task.id, step[:progress])
          @push_manager.notify_artifact_update(task.id, artifact)
        end
      end

      # Generate final artifact
      final_artifact = create_final_artifact(task.id)

      # Complete task
      task = A2A::Models::Task.new(
        id: task.id,
        session_id: task.session_id,
        status: {
          state: 'completed',
          message: A2A::Models::Message.text(
            role: 'agent',
            text: "Processing complete"
          ),
          timestamp: Time.now.utc.iso8601
        },
        artifacts: [final_artifact],
        metadata: task.metadata
      )

      @task_store[task.id] = task
      @push_manager.notify_status_update(task)

      # Clean up configuration
      @push_manager.remove_config(task.id)

    rescue StandardError => e
      debug_me "Task processing error: #{e.message}"

      task = update_task(task, 'failed', e.message)
      @task_store[task.id] = task
      @push_manager.notify_status_update(task)
      @push_manager.remove_config(task.id)
    end
  end

  def update_task(task, state, message_text)
    updated = A2A::Models::Task.new(
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

    @task_store[task.id] = updated
    updated
  end

  def create_intermediate_artifact(task_id, progress)
    A2A::Models::Artifact.new(
      name: "Progress Report",
      parts: [
        A2A::Models::DataPart.new(
          data: {
            progress: progress,
            status: "In Progress",
            timestamp: Time.now.utc.iso8601
          }
        )
      ]
    )
  end

  def create_final_artifact(task_id)
    A2A::Models::Artifact.new(
      name: "Final Results",
      description: "Complete processing results",
      parts: [
        A2A::Models::TextPart.new(
          text: "Processing completed successfully"
        ),
        A2A::Models::DataPart.new(
          data: {
            total_processed: 10000,
            success_rate: 0.98,
            completion_time: Time.now.utc.iso8601
          }
        )
      ],
      metadata: {
        task_id: task_id,
        version: "1.0"
      }
    )
  end
end
```

### Client-Side Webhook Receiver

#### Sinatra Webhook Endpoint

```ruby
require 'sinatra'
require 'json'
require 'securerandom'

# Webhook verification token
WEBHOOK_TOKEN = ENV['WEBHOOK_TOKEN'] || SecureRandom.hex(32)

# Store to track task updates
task_updates = {}

# Webhook endpoint
post '/webhooks/a2a' do
  request.body.rewind
  payload_body = request.body.read

  # Verify webhook token
  provided_token = request.env['HTTP_X_WEBHOOK_TOKEN']

  unless provided_token == WEBHOOK_TOKEN
    halt 401, JSON.generate({ error: 'Invalid webhook token' })
  end

  # Parse payload
  begin
    payload = JSON.parse(payload_body, symbolize_names: true)
  rescue JSON::ParserError
    halt 400, JSON.generate({ error: 'Invalid JSON' })
  end

  # Extract task ID and event
  task_id = payload[:taskId]
  event = payload[:event]
  event_type = event[:type]

  debug_me "Received webhook: #{event_type} for task #{task_id}"

  # Process event
  case event_type
  when 'TaskStatusUpdateEvent'
    handle_status_update(task_id, event[:task], task_updates)

  when 'TaskArtifactUpdateEvent'
    handle_artifact_update(task_id, event[:artifact], task_updates)

  else
    debug_me "Unknown event type: #{event_type}"
  end

  # Return 200 OK to acknowledge receipt
  status 200
  content_type :json
  JSON.generate({ received: true })
end

def handle_status_update(task_id, task_data, store)
  task = A2A::Models::Task.from_hash(task_data)

  # Store update
  store[task_id] ||= { task: nil, artifacts: [] }
  store[task_id][:task] = task

  # Log status
  state = task.status.state.value
  message = task.status.message&.parts&.first&.text

  debug_me "Task #{task_id}: #{state}"
  debug_me "  Message: #{message}" if message

  # Handle terminal states
  if task.status.state.terminal?
    debug_me "Task #{task_id} reached terminal state: #{state}"

    # Could trigger additional processing here
    case state
    when 'completed'
      handle_task_completion(task_id, store)
    when 'failed'
      handle_task_failure(task_id, store)
    end
  end
end

def handle_artifact_update(task_id, artifact_data, store)
  artifact = A2A::Models::Artifact.from_hash(artifact_data)

  # Store artifact
  store[task_id] ||= { task: nil, artifacts: [] }
  store[task_id][:artifacts] << artifact

  debug_me "Task #{task_id}: Received artifact '#{artifact.name}'"

  # Process artifact content
  artifact.parts.each do |part|
    case part
    when A2A::Models::TextPart
      debug_me "  Text: #{part.text[0..100]}..."

    when A2A::Models::DataPart
      debug_me "  Data: #{part.data.keys.join(', ')}"

    when A2A::Models::FilePart
      if part.file[:bytes]
        save_artifact_file(task_id, artifact.name, part.file[:bytes])
      end
    end
  end
end

def handle_task_completion(task_id, store)
  debug_me "Processing completed task #{task_id}"

  task_data = store[task_id]
  task = task_data[:task]
  artifacts = task_data[:artifacts]

  debug_me "  Total artifacts: #{artifacts.size}"

  # Process final results
  # ... custom logic here ...
end

def handle_task_failure(task_id, store)
  debug_me "Processing failed task #{task_id}"

  task = store[task_id][:task]
  error_message = task.status.message&.parts&.first&.text

  debug_me "  Error: #{error_message}"

  # Handle failure
  # ... custom logic here ...
end

def save_artifact_file(task_id, artifact_name, base64_bytes)
  filename = "downloads/#{task_id}/#{artifact_name.gsub(/\s+/, '_')}"
  FileUtils.mkdir_p(File.dirname(filename))

  File.write(filename, Base64.decode64(base64_bytes))
  debug_me "  Saved file: #{filename}"
end
```

#### Client Implementation

```ruby
require 'a2a'
require 'http'
require 'json'

class A2APushClient < A2A::Client::Base
  def initialize(agent_url, webhook_url, webhook_token)
    super(agent_url)
    @webhook_url = webhook_url
    @webhook_token = webhook_token
    @http_client = HTTP.timeout(connect: 5, write: 10, read: 10)
  end

  def send_task_with_push(task_id:, message:, session_id: nil)
    # Step 1: Send task
    task = send_task(
      task_id: task_id,
      message: message,
      session_id: session_id
    )

    # Step 2: Configure push notifications
    set_push_notification(
      task_id: task_id,
      config: build_push_config
    )

    debug_me "Task #{task_id} submitted with push notifications"
    task
  end

  def send_task(task_id:, message:, session_id: nil)
    task = A2A::Models::Task.new(
      id: task_id,
      session_id: session_id,
      status: {
        state: 'submitted',
        timestamp: Time.now.utc.iso8601
      }
    )

    request = {
      jsonrpc: "2.0",
      id: task_id,
      method: "tasks/send",
      params: {
        task: task.to_h,
        message: message.to_h
      }
    }

    response = @http_client.post(
      agent_url,
      json: request,
      headers: { 'Content-Type' => 'application/json' }
    )

    unless response.status.success?
      raise A2A::InternalError, "HTTP #{response.status}: #{response.body}"
    end

    result = JSON.parse(response.body, symbolize_names: true)
    A2A::Models::Task.from_hash(result[:result])
  end

  def set_push_notification(task_id:, config:)
    request = {
      jsonrpc: "2.0",
      id: SecureRandom.uuid,
      method: "tasks/pushNotification/set",
      params: {
        taskId: task_id,
        config: config.to_h
      }
    }

    response = @http_client.post(
      agent_url,
      json: request,
      headers: { 'Content-Type' => 'application/json' }
    )

    unless response.status.success?
      raise A2A::InternalError, "Failed to set push notification: #{response.body}"
    end

    debug_me "Push notification configured for task #{task_id}"
  end

  def get_push_notification(task_id:)
    request = {
      jsonrpc: "2.0",
      id: SecureRandom.uuid,
      method: "tasks/pushNotification/get",
      params: {
        taskId: task_id
      }
    }

    response = @http_client.post(
      agent_url,
      json: request,
      headers: { 'Content-Type' => 'application/json' }
    )

    unless response.status.success?
      raise A2A::InternalError, "Failed to get push notification: #{response.body}"
    end

    result = JSON.parse(response.body, symbolize_names: true)
    A2A::Models::PushNotificationConfig.from_hash(result[:result])
  end

  private

  def build_push_config
    A2A::Models::PushNotificationConfig.new(
      url: @webhook_url,
      token: @webhook_token,
      authentication: nil # Add if needed
    )
  end
end
```

## Security

### Webhook Token Verification

Always verify webhook requests:

```ruby
def verify_webhook_token(request)
  provided_token = request.env['HTTP_X_WEBHOOK_TOKEN']
  expected_token = ENV['WEBHOOK_TOKEN']

  unless provided_token && provided_token == expected_token
    halt 401, JSON.generate({ error: 'Unauthorized' })
  end
end
```

### HTTPS Only

```ruby
def validate_webhook_url(url)
  uri = URI.parse(url)

  unless uri.scheme == 'https'
    raise ArgumentError, "Webhook URL must use HTTPS"
  end

  unless uri.host
    raise ArgumentError, "Webhook URL must have a valid host"
  end
rescue URI::InvalidURIError => e
  raise ArgumentError, "Invalid webhook URL: #{e.message}"
end
```

### Request Signing

For enhanced security, sign webhook payloads:

```ruby
require 'openssl'

class SignedWebhookManager < PushNotificationManager
  def initialize(signing_secret)
    super()
    @signing_secret = signing_secret
  end

  private

  def send_notification(config, event, attempt: 1)
    payload = JSON.generate(event)
    signature = generate_signature(payload)

    headers = build_headers(config).merge({
      'X-Webhook-Signature' => signature,
      'X-Webhook-Timestamp' => Time.now.to_i.to_s
    })

    response = HTTP.headers(headers).post(config.url, body: payload)

    # ... handle response ...
  end

  def generate_signature(payload)
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'),
      @signing_secret,
      payload
    )
  end
end

# Client verification
def verify_webhook_signature(request, signing_secret)
  payload = request.body.read
  request.body.rewind

  provided_signature = request.env['HTTP_X_WEBHOOK_SIGNATURE']
  timestamp = request.env['HTTP_X_WEBHOOK_TIMESTAMP']

  # Prevent replay attacks (5 minute window)
  if timestamp.to_i < Time.now.to_i - 300
    halt 401, JSON.generate({ error: 'Webhook expired' })
  end

  expected_signature = OpenSSL::HMAC.hexdigest(
    OpenSSL::Digest.new('sha256'),
    signing_secret,
    payload
  )

  unless secure_compare(provided_signature, expected_signature)
    halt 401, JSON.generate({ error: 'Invalid signature' })
  end
end

def secure_compare(a, b)
  return false unless a.bytesize == b.bytesize

  l = a.unpack("C#{a.bytesize}")
  res = 0
  b.each_byte { |byte| res |= byte ^ l.shift }
  res == 0
end
```

## Retry Logic

### Exponential Backoff

```ruby
def send_with_retry(config, event, attempt: 1)
  max_attempts = 5
  base_delay = 2 # seconds

  begin
    send_notification(config, event)

  rescue HTTP::Error => e
    if attempt < max_attempts
      delay = base_delay ** attempt # 2, 4, 8, 16, 32 seconds
      debug_me "Retry #{attempt}/#{max_attempts} in #{delay}s"

      sleep(delay)
      send_with_retry(config, event, attempt: attempt + 1)
    else
      debug_me "Failed after #{max_attempts} attempts"
      store_in_dead_letter_queue(config, event)
    end
  end
end
```

### Circuit Breaker Pattern

```ruby
class WebhookCircuitBreaker
  def initialize(failure_threshold: 5, timeout: 60)
    @failure_threshold = failure_threshold
    @timeout = timeout
    @failures = Hash.new(0)
    @opened_at = {}
  end

  def call(url)
    if circuit_open?(url)
      raise CircuitOpenError, "Circuit breaker open for #{url}"
    end

    begin
      yield
      reset_failures(url)
    rescue StandardError => e
      record_failure(url)
      raise e
    end
  end

  private

  def circuit_open?(url)
    return false unless @opened_at[url]

    # Check if timeout has passed
    if Time.now - @opened_at[url] > @timeout
      reset_failures(url)
      false
    else
      true
    end
  end

  def record_failure(url)
    @failures[url] += 1

    if @failures[url] >= @failure_threshold
      @opened_at[url] = Time.now
      debug_me "Circuit breaker opened for #{url}"
    end
  end

  def reset_failures(url)
    @failures.delete(url)
    @opened_at.delete(url)
  end
end
```

## Best Practices

### 1. Always Return 200 OK Quickly

```ruby
post '/webhooks/a2a' do
  # Verify token
  verify_webhook_token(request)

  # Parse payload
  payload = JSON.parse(request.body.read, symbolize_names: true)

  # Process asynchronously
  Thread.new do
    process_webhook_payload(payload)
  end

  # Return immediately
  status 200
  JSON.generate({ received: true })
end
```

### 2. Implement Idempotency

```ruby
class WebhookReceiver
  def initialize
    @processed_events = Set.new
  end

  def handle_webhook(payload)
    event_id = generate_event_id(payload)

    if @processed_events.include?(event_id)
      debug_me "Duplicate event #{event_id}, skipping"
      return
    end

    @processed_events.add(event_id)

    # Process event
    process_event(payload)
  end

  private

  def generate_event_id(payload)
    # Combine task ID and event type and timestamp
    "#{payload[:taskId]}-#{payload[:event][:type]}-#{payload[:event][:task][:status][:timestamp]}"
  end
end
```

### 3. Store Webhook History

```ruby
class WebhookLogger
  def log_webhook(payload, status)
    DB[:webhook_logs].insert(
      task_id: payload[:taskId],
      event_type: payload[:event][:type],
      payload: JSON.generate(payload),
      status: status,
      received_at: Time.now
    )
  end
end
```

### 4. Monitor Webhook Health

```ruby
class WebhookMonitor
  def initialize
    @metrics = {
      received: 0,
      processed: 0,
      failed: 0
    }
  end

  def record_received
    @metrics[:received] += 1
  end

  def record_processed
    @metrics[:processed] += 1
  end

  def record_failed
    @metrics[:failed] += 1
  end

  def report
    {
      received: @metrics[:received],
      processed: @metrics[:processed],
      failed: @metrics[:failed],
      success_rate: calculate_success_rate
    }
  end

  private

  def calculate_success_rate
    return 0.0 if @metrics[:received].zero?

    (@metrics[:processed].to_f / @metrics[:received] * 100).round(2)
  end
end
```

## Complete Examples

### Background Job Processing

```ruby
# Server-side background job processor
class BackgroundJobServer < A2APushServer
  def handle_send_task(params)
    task = A2A::Models::Task.from_hash(params['task'])
    message = A2A::Models::Message.from_hash(params['message'])

    # Extract job type from message
    job_type = extract_job_type(message)

    # Queue job for processing
    job_id = queue_job(task.id, job_type, message)

    debug_me "Job #{job_id} queued for task #{task.id}"

    # Return immediately
    task
  end

  private

  def queue_job(task_id, job_type, message)
    job = {
      id: SecureRandom.uuid,
      task_id: task_id,
      type: job_type,
      message: message,
      created_at: Time.now
    }

    @job_queue << job

    # Start worker if needed
    ensure_worker_running

    job[:id]
  end

  def ensure_worker_running
    return if @worker_running

    @worker_running = true

    Thread.new do
      loop do
        process_next_job
        sleep(1)
      end
    end
  end

  def process_next_job
    return if @job_queue.empty?

    job = @job_queue.pop
    task_id = job[:task_id]
    task = @task_store[task_id]

    begin
      # Update to working
      task = update_task(task, 'working', "Processing #{job[:type]}...")
      @push_manager.notify_status_update(task)

      # Process job based on type
      result = case job[:type]
      when 'video_encoding'
        process_video_encoding(job)
      when 'data_analysis'
        process_data_analysis(job)
      when 'report_generation'
        process_report_generation(job)
      else
        raise "Unknown job type: #{job[:type]}"
      end

      # Create result artifact
      artifact = create_result_artifact(task_id, result)

      # Complete task
      task = A2A::Models::Task.new(
        id: task.id,
        session_id: task.session_id,
        status: {
          state: 'completed',
          message: A2A::Models::Message.text(
            role: 'agent',
            text: "Job completed: #{job[:type]}"
          ),
          timestamp: Time.now.utc.iso8601
        },
        artifacts: [artifact]
      )

      @task_store[task_id] = task
      @push_manager.notify_status_update(task)
      @push_manager.remove_config(task_id)

    rescue StandardError => e
      debug_me "Job processing error: #{e.message}"
      task = update_task(task, 'failed', e.message)
      @push_manager.notify_status_update(task)
      @push_manager.remove_config(task_id)
    end
  end

  def process_video_encoding(job)
    # Simulate video encoding
    10.times do |i|
      sleep(2)
      progress = ((i + 1) * 10)
      task = @task_store[job[:task_id]]
      task = update_task(task, 'working', "Encoding: #{progress}%")
      @push_manager.notify_status_update(task)
    end

    { format: 'mp4', size: 1024000, duration: 120 }
  end

  def process_data_analysis(job)
    # Simulate data analysis
    { insights: ["trend1", "trend2"], confidence: 0.95 }
  end

  def process_report_generation(job)
    # Simulate report generation
    { pages: 25, charts: 8, tables: 12 }
  end
end
```

## Testing Strategies

### Testing Webhook Delivery

```ruby
require 'webmock/rspec'

RSpec.describe PushNotificationManager do
  let(:manager) { described_class.new }

  describe '#notify_status_update' do
    it 'sends POST request to webhook URL' do
      config = {
        url: 'https://client.test/webhook',
        token: 'test-token'
      }

      manager.set_config('task-1', config)

      task = build_task(id: 'task-1', state: 'working')

      stub = stub_request(:post, 'https://client.test/webhook')
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'X-Webhook-Token' => 'test-token'
          }
        )
        .to_return(status: 200)

      manager.notify_status_update(task)

      expect(stub).to have_been_requested
    end
  end
end
```

### Testing Webhook Receiver

```ruby
RSpec.describe 'Webhook endpoint' do
  it 'accepts valid webhook payloads' do
    payload = {
      taskId: 'task-1',
      event: {
        type: 'TaskStatusUpdateEvent',
        task: build_task_hash
      }
    }

    header 'X-Webhook-Token', WEBHOOK_TOKEN

    post '/webhooks/a2a', JSON.generate(payload),
         { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(200)
  end

  it 'rejects requests with invalid token' do
    payload = { taskId: 'task-1', event: {} }

    header 'X-Webhook-Token', 'invalid'

    post '/webhooks/a2a', JSON.generate(payload),
         { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(401)
  end
end
```

## Troubleshooting

### Issue: Webhook Not Receiving Requests

**Solutions**:
1. Verify URL is publicly accessible
2. Check firewall rules
3. Test with webhook.site or requestbin.com
4. Verify HTTPS certificate is valid

```ruby
# Test webhook URL
def test_webhook_url(url)
  response = HTTP.post(url, json: { test: true })

  if response.status.success?
    debug_me "Webhook URL is reachable"
  else
    debug_me "Webhook URL returned #{response.status}"
  end
rescue HTTP::Error => e
  debug_me "Webhook URL unreachable: #{e.message}"
end
```

### Issue: Duplicate Webhook Deliveries

**Solution**: Implement idempotency keys

```ruby
def handle_webhook_with_idempotency(payload)
  idempotency_key = extract_idempotency_key(payload)

  if already_processed?(idempotency_key)
    debug_me "Skipping duplicate webhook: #{idempotency_key}"
    return
  end

  mark_as_processed(idempotency_key)
  process_webhook(payload)
end
```

### Issue: Webhook Timeout

**Solution**: Return 200 immediately, process async

```ruby
post '/webhooks/a2a' do
  payload = JSON.parse(request.body.read)

  # Queue for async processing
  WEBHOOK_QUEUE << payload

  # Return immediately
  status 200
  JSON.generate({ received: true })
end
```

---

## Related Documentation

- [Streaming](streaming.md) - Alternative for real-time updates
- [Multi-Turn Conversations](conversations.md) - Session management
- [Error Handling](../guides/errors.md) - Error handling guide
- [Task Lifecycle](../guides/tasks.md) - Understanding task states

## Further Reading

- [Webhook Security Best Practices](https://webhooks.fyi/security/overview)
- [A2A Protocol Specification](../protocol-spec.md)
- [JSON-RPC 2.0](https://www.jsonrpc.org/specification)
