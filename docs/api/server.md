# Server API Reference

Complete reference for the A2A server base class (`A2A::Server::Base`).

## Overview

The Server layer provides a base class for implementing A2A servers that expose A2A protocol endpoints. Servers handle incoming JSON-RPC requests, manage task lifecycle, support streaming, and provide push notifications.

**Source:** `lib/a2a/server/base.rb`

## Table of Contents

- [Class: A2A::Server::Base](#class-a2aserverbase)
  - [Constructor](#constructor)
  - [Instance Attributes](#instance-attributes)
  - [Instance Methods](#instance-methods)
    - [Request Handling](#request-handling)
    - [Task Management](#task-management)
    - [Push Notifications](#push-notifications)
    - [Streaming](#streaming)
- [Implementation Guide](#implementation-guide)
- [Usage Examples](#usage-examples)

---

## Class: A2A::Server::Base

Base class for A2A servers. An A2A server exposes an HTTP endpoint that implements the A2A protocol methods.

This is an abstract base class that defines the interface for A2A servers. Subclasses must implement the abstract methods to provide concrete agent implementations.

### Constructor

```ruby
A2A::Server::Base.new(agent_card)
```

**Parameters:**

- `agent_card` (A2A::Models::AgentCard, required) - The agent's metadata and capabilities

**Returns:** `Server::Base` instance

**Example:**

```ruby
class MyA2AServer < A2A::Server::Base
  # Implementation here
end

agent_card = A2A::Models::AgentCard.new(
  name: 'DataAnalyzer',
  url: 'https://myagent.example.com',
  version: '1.0.0',
  capabilities: { streaming: true },
  skills: [...]
)

server = MyA2AServer.new(agent_card)
```

---

### Instance Attributes

#### `#agent_card`

Returns the agent's metadata and capabilities.

**Returns:** `A2A::Models::AgentCard`

**Example:**

```ruby
server.agent_card.name  # => "DataAnalyzer"
server.agent_card.version  # => "1.0.0"
server.agent_card.capabilities.streaming?  # => true
```

---

### Instance Methods

#### Request Handling

##### `#handle_request(request)`

Handle an incoming A2A request. This is the main entry point for processing JSON-RPC requests.

**Parameters:**

- `request` (Hash) - The JSON-RPC request hash

**Returns:** `Hash` - The JSON-RPC response hash

**Raises:** `NotImplementedError` - Subclasses must implement this method

**Example Implementation:**

```ruby
class MyA2AServer < A2A::Server::Base
  def handle_request(request)
    req = A2A::Protocol::Request.from_hash(request)

    begin
      result = case req.method
               when 'tasks/send'
                 handle_send_task(req.params).to_h
               when 'tasks/sendSubscribe'
                 # Streaming handled separately
                 raise A2A::UnsupportedOperationError.new
               when 'tasks/get'
                 handle_get_task(req.params).to_h
               when 'tasks/cancel'
                 handle_cancel_task(req.params).to_h
               when 'tasks/pushNotification/set'
                 handle_set_push_notification(req.params)
                 {}
               when 'tasks/pushNotification/get'
                 handle_get_push_notification(req.params).to_h
               else
                 raise A2A::MethodNotFoundError.new
               end

      A2A::Protocol::Response.success(id: req.id, result: result).to_h

    rescue A2A::JSONRPCError => e
      error = A2A::Protocol::Error.from_exception(e)
      A2A::Protocol::Response.error(id: req.id, error: error.to_h).to_h
    end
  end
end
```

**Usage in Web Framework:**

```ruby
# Sinatra example
post '/' do
  content_type :json

  request_data = JSON.parse(request.body.read)
  response_data = server.handle_request(request_data)

  response_data.to_json
end

# Rails example
class A2AController < ApplicationController
  def handle
    response_data = @server.handle_request(params.to_unsafe_h)
    render json: response_data
  end
end
```

---

#### Task Management

##### `#handle_send_task(params)`

Handle a `tasks/send` request - submit a new task.

**Parameters:**

- `params` (Hash) - Request parameters containing:
  - `taskId` (String) - Unique task identifier
  - `message` (Hash) - Message data
  - `sessionId` (String, optional) - Session identifier

**Returns:** `A2A::Models::Task` - The created task

**Raises:** `NotImplementedError` - Subclasses must implement this method

**Example Implementation:**

```ruby
class MyA2AServer < A2A::Server::Base
  def handle_send_task(params)
    task_id = params['taskId'] || params[:taskId]
    session_id = params['sessionId'] || params[:sessionId]
    message_data = params['message'] || params[:message]

    message = A2A::Models::Message.from_hash(message_data)

    # Process the task
    task = process_task(task_id, message, session_id)

    task
  end

  private

  def process_task(task_id, message, session_id)
    # Store the task
    @tasks ||= {}
    @tasks[task_id] = A2A::Models::Task.new(
      id: task_id,
      session_id: session_id,
      status: { state: 'submitted' }
    )

    # Start processing asynchronously
    Thread.new do
      perform_task_work(task_id, message)
    end

    @tasks[task_id]
  end

  def perform_task_work(task_id, message)
    # Update to working
    @tasks[task_id] = A2A::Models::Task.new(
      id: task_id,
      session_id: @tasks[task_id].session_id,
      status: { state: 'working' }
    )

    # Do the actual work
    result = your_agent_logic(message)

    # Create artifacts
    artifacts = [
      A2A::Models::Artifact.new(
        name: 'result',
        parts: [A2A::Models::TextPart.new(text: result)]
      )
    ]

    # Update to completed
    @tasks[task_id] = A2A::Models::Task.new(
      id: task_id,
      session_id: @tasks[task_id].session_id,
      status: { state: 'completed' },
      artifacts: artifacts
    )
  rescue => e
    # Update to failed
    @tasks[task_id] = A2A::Models::Task.new(
      id: task_id,
      session_id: @tasks[task_id].session_id,
      status: {
        state: 'failed',
        message: A2A::Models::Message.text(role: 'agent', text: e.message)
      }
    )
  end
end
```

---

##### `#handle_send_task_streaming(params, &block)`

Handle a `tasks/sendSubscribe` request - submit a task with streaming updates.

**Parameters:**

- `params` (Hash) - Request parameters
- `block` (Block, required) - Block that yields streaming events

**Yields:** Event hashes (task status and artifact updates)

**Returns:** Implementation-defined

**Raises:** `NotImplementedError` - Subclasses must implement this method

**Example Implementation:**

```ruby
class MyA2AServer < A2A::Server::Base
  def handle_send_task_streaming(params, &block)
    task_id = params['taskId'] || params[:taskId]
    session_id = params['sessionId'] || params[:sessionId]
    message_data = params['message'] || params[:message]

    message = A2A::Models::Message.from_hash(message_data)

    # Send initial status
    status = A2A::Models::TaskStatus.new(state: 'submitted')
    yield({
      type: 'taskStatus',
      taskStatus: status.to_h
    })

    # Process with streaming
    process_task_streaming(task_id, message, session_id, &block)
  end

  private

  def process_task_streaming(task_id, message, session_id)
    # Update to working
    status = A2A::Models::TaskStatus.new(state: 'working')
    yield({
      type: 'taskStatus',
      taskStatus: status.to_h
    })

    # Stream results as they're generated
    your_agent_logic_streaming(message) do |chunk|
      artifact = A2A::Models::Artifact.new(
        name: 'result',
        parts: [A2A::Models::TextPart.new(text: chunk)],
        append: true
      )

      yield({
        type: 'artifactUpdate',
        artifact: artifact.to_h
      })
    end

    # Send final status
    status = A2A::Models::TaskStatus.new(state: 'completed')
    yield({
      type: 'taskStatus',
      taskStatus: status.to_h
    })
  rescue => e
    status = A2A::Models::TaskStatus.new(
      state: 'failed',
      message: A2A::Models::Message.text(role: 'agent', text: e.message)
    )
    yield({
      type: 'taskStatus',
      taskStatus: status.to_h
    })
  end
end
```

**Usage in Web Framework:**

```ruby
# Sinatra with Server-Sent Events
get '/stream/:task_id' do
  content_type 'text/event-stream'

  stream :keep_open do |out|
    server.handle_send_task_streaming(params) do |event|
      out << "data: #{event.to_json}\n\n"
    end
    out.close
  end
end
```

---

##### `#handle_get_task(params)`

Handle a `tasks/get` request - get task status.

**Parameters:**

- `params` (Hash) - Request parameters containing:
  - `taskId` (String) - Task identifier

**Returns:** `A2A::Models::Task` - The task

**Raises:**
  - `NotImplementedError` - Subclasses must implement this method
  - `A2A::TaskNotFoundError` - If task doesn't exist

**Example Implementation:**

```ruby
class MyA2AServer < A2A::Server::Base
  def handle_get_task(params)
    task_id = params['taskId'] || params[:taskId]

    @tasks ||= {}
    task = @tasks[task_id]

    raise A2A::TaskNotFoundError.new unless task

    task
  end
end
```

---

##### `#handle_cancel_task(params)`

Handle a `tasks/cancel` request - cancel a task.

**Parameters:**

- `params` (Hash) - Request parameters containing:
  - `taskId` (String) - Task identifier

**Returns:** `A2A::Models::Task` - The canceled task

**Raises:**
  - `NotImplementedError` - Subclasses must implement this method
  - `A2A::TaskNotFoundError` - If task doesn't exist
  - `A2A::TaskNotCancelableError` - If task cannot be canceled

**Example Implementation:**

```ruby
class MyA2AServer < A2A::Server::Base
  def handle_cancel_task(params)
    task_id = params['taskId'] || params[:taskId]

    @tasks ||= {}
    task = @tasks[task_id]

    raise A2A::TaskNotFoundError.new unless task

    # Check if cancelable
    if task.state.terminal?
      raise A2A::TaskNotCancelableError.new
    end

    # Cancel the task
    @task_threads ||= {}
    @task_threads[task_id]&.kill

    # Update task state
    @tasks[task_id] = A2A::Models::Task.new(
      id: task_id,
      session_id: task.session_id,
      status: { state: 'canceled' },
      artifacts: task.artifacts
    )

    @tasks[task_id]
  end
end
```

---

#### Push Notifications

##### `#handle_set_push_notification(params)`

Handle a `tasks/pushNotification/set` request.

**Parameters:**

- `params` (Hash) - Request parameters containing:
  - `taskId` (String) - Task identifier
  - `config` (Hash) - Push notification configuration

**Returns:** Implementation-defined (typically nil or empty hash)

**Raises:**
  - `NotImplementedError` - Subclasses must implement this method
  - `A2A::PushNotificationNotSupportedError` - If not supported

**Example Implementation:**

```ruby
class MyA2AServer < A2A::Server::Base
  def handle_set_push_notification(params)
    # Check if push notifications are supported
    unless @agent_card.capabilities.push_notifications?
      raise A2A::PushNotificationNotSupportedError.new
    end

    task_id = params['taskId'] || params[:taskId]
    config_data = params['config'] || params[:config]

    config = A2A::Models::PushNotificationConfig.from_hash(config_data)

    # Store the configuration
    @push_configs ||= {}
    @push_configs[task_id] = config

    nil
  end
end
```

---

##### `#handle_get_push_notification(params)`

Handle a `tasks/pushNotification/get` request.

**Parameters:**

- `params` (Hash) - Request parameters containing:
  - `taskId` (String) - Task identifier

**Returns:** `A2A::Models::PushNotificationConfig` - The configuration

**Raises:**
  - `NotImplementedError` - Subclasses must implement this method
  - `A2A::PushNotificationNotSupportedError` - If not supported

**Example Implementation:**

```ruby
class MyA2AServer < A2A::Server::Base
  def handle_get_push_notification(params)
    unless @agent_card.capabilities.push_notifications?
      raise A2A::PushNotificationNotSupportedError.new
    end

    task_id = params['taskId'] || params[:taskId]

    @push_configs ||= {}
    config = @push_configs[task_id]

    config || A2A::Models::PushNotificationConfig.new(url: '')
  end
end
```

---

#### Streaming

##### `#handle_resubscribe(params, &block)`

Handle a `tasks/resubscribe` request - resubscribe to task updates.

**Parameters:**

- `params` (Hash) - Request parameters containing:
  - `taskId` (String) - Task identifier
- `block` (Block, required) - Block that yields streaming events

**Yields:** Event hashes (task status and artifact updates)

**Returns:** Implementation-defined

**Raises:** `NotImplementedError` - Subclasses must implement this method

**Example Implementation:**

```ruby
class MyA2AServer < A2A::Server::Base
  def handle_resubscribe(params, &block)
    task_id = params['taskId'] || params[:taskId]

    @tasks ||= {}
    task = @tasks[task_id]

    raise A2A::TaskNotFoundError.new unless task

    # Send current status
    yield({
      type: 'taskStatus',
      taskStatus: task.status.to_h
    })

    # Send current artifacts
    task.artifacts&.each do |artifact|
      yield({
        type: 'artifactUpdate',
        artifact: artifact.to_h
      })
    end

    # Subscribe to future updates if task is not terminal
    unless task.state.terminal?
      subscribe_to_updates(task_id, &block)
    end
  end

  private

  def subscribe_to_updates(task_id)
    # Implementation depends on your architecture
    # Could use pub/sub, polling, etc.
  end
end
```

---

## Implementation Guide

### Creating a Custom Server

To create a working A2A server, you must:

1. Define your agent's capabilities in an AgentCard
2. Subclass `A2A::Server::Base`
3. Implement all abstract methods
4. Handle task storage and lifecycle
5. Integrate with a web framework (Sinatra, Rails, etc.)
6. Serve the AgentCard at `/.well-known/agent.json`

### Minimal Implementation

```ruby
require 'a2a'
require 'sinatra'
require 'json'

class SimpleA2AServer < A2A::Server::Base
  def initialize(agent_card)
    super(agent_card)
    @tasks = {}
  end

  def handle_request(request)
    req = A2A::Protocol::Request.from_hash(request)

    begin
      result = case req.method
               when 'tasks/send' then handle_send_task(req.params).to_h
               when 'tasks/get' then handle_get_task(req.params).to_h
               when 'tasks/cancel' then handle_cancel_task(req.params).to_h
               else raise A2A::MethodNotFoundError.new
               end

      A2A::Protocol::Response.success(id: req.id, result: result).to_h
    rescue A2A::JSONRPCError => e
      error = A2A::Protocol::Error.from_exception(e)
      A2A::Protocol::Response.error(id: req.id, error: error.to_h).to_h
    end
  end

  def handle_send_task(params)
    task_id = params['taskId']
    message = A2A::Models::Message.from_hash(params['message'])

    @tasks[task_id] = A2A::Models::Task.new(
      id: task_id,
      status: { state: 'submitted' }
    )

    Thread.new { process_task(task_id, message) }

    @tasks[task_id]
  end

  def handle_send_task_streaming(params, &block)
    raise A2A::UnsupportedOperationError.new
  end

  def handle_get_task(params)
    task = @tasks[params['taskId']]
    raise A2A::TaskNotFoundError.new unless task
    task
  end

  def handle_cancel_task(params)
    task = @tasks[params['taskId']]
    raise A2A::TaskNotFoundError.new unless task
    raise A2A::TaskNotCancelableError.new if task.state.terminal?

    @tasks[params['taskId']] = A2A::Models::Task.new(
      id: task.id,
      status: { state: 'canceled' }
    )
  end

  def handle_set_push_notification(params)
    raise A2A::PushNotificationNotSupportedError.new
  end

  def handle_get_push_notification(params)
    raise A2A::PushNotificationNotSupportedError.new
  end

  def handle_resubscribe(params, &block)
    raise A2A::UnsupportedOperationError.new
  end

  private

  def process_task(task_id, message)
    sleep 2  # Simulate work

    result_text = "Processed: #{message.parts.first.text}"
    artifact = A2A::Models::Artifact.new(
      name: 'result',
      parts: [A2A::Models::TextPart.new(text: result_text)]
    )

    @tasks[task_id] = A2A::Models::Task.new(
      id: task_id,
      status: { state: 'completed' },
      artifacts: [artifact]
    )
  end
end

# Create agent card
agent_card = A2A::Models::AgentCard.new(
  name: 'SimpleAgent',
  url: 'http://localhost:4567',
  version: '1.0.0',
  capabilities: { streaming: false },
  skills: [
    {
      id: 'echo',
      name: 'Echo',
      description: 'Echoes back your message'
    }
  ]
)

# Create server
server = SimpleA2AServer.new(agent_card)

# Serve agent card
get '/.well-known/agent.json' do
  content_type :json
  server.agent_card.to_json
end

# Handle A2A requests
post '/' do
  content_type :json
  request_data = JSON.parse(request.body.read)
  response_data = server.handle_request(request_data)
  response_data.to_json
end
```

---

## Usage Examples

### Complete Server with Rails

```ruby
# app/controllers/a2a_controller.rb
class A2aController < ApplicationController
  skip_before_action :verify_authenticity_token

  def agent_card
    render json: a2a_server.agent_card.to_h
  end

  def handle_request
    response_data = a2a_server.handle_request(request_params)
    render json: response_data
  end

  private

  def a2a_server
    @a2a_server ||= MyA2AServer.new(build_agent_card)
  end

  def build_agent_card
    A2A::Models::AgentCard.new(
      name: 'MyAgent',
      url: request.base_url,
      version: '1.0.0',
      capabilities: {
        streaming: true,
        push_notifications: false
      },
      skills: AgentSkill.all.map(&:to_a2a_skill)
    )
  end

  def request_params
    params.permit!.to_h
  end
end

# config/routes.rb
Rails.application.routes.draw do
  get '/.well-known/agent.json', to: 'a2a#agent_card'
  post '/a2a', to: 'a2a#handle_request'
end
```

### Server with Background Jobs

```ruby
class MyA2AServer < A2A::Server::Base
  def handle_send_task(params)
    task_id = params['taskId']
    message = A2A::Models::Message.from_hash(params['message'])

    # Store initial task
    task = Task.create!(
      task_id: task_id,
      state: 'submitted',
      message_data: message.to_h
    )

    # Enqueue background job
    ProcessTaskJob.perform_later(task_id)

    # Return task
    task.to_a2a_task
  end

  def handle_get_task(params)
    task = Task.find_by(task_id: params['taskId'])
    raise A2A::TaskNotFoundError.new unless task

    task.to_a2a_task
  end
end

# app/jobs/process_task_job.rb
class ProcessTaskJob < ApplicationJob
  def perform(task_id)
    task = Task.find_by(task_id: task_id)
    return unless task

    # Update to working
    task.update!(state: 'working')

    # Do the work
    result = YourAgentService.process(task.message_data)

    # Create artifacts
    artifact_data = {
      name: 'result',
      parts: [{ type: 'text', text: result }]
    }

    # Update to completed
    task.update!(
      state: 'completed',
      artifacts_data: [artifact_data]
    )

    # Send push notification if configured
    send_push_notification(task) if task.push_config.present?
  rescue => e
    task.update!(
      state: 'failed',
      error_message: e.message
    )
  end

  private

  def send_push_notification(task)
    # Send HTTP POST to client's push notification URL
    config = task.push_notification_config
    # ... implementation ...
  end
end
```

### Streaming Implementation

```ruby
class StreamingA2AServer < A2A::Server::Base
  def handle_send_task_streaming(params, &block)
    task_id = params['taskId']
    message = A2A::Models::Message.from_hash(params['message'])

    # Send initial status
    yield({
      type: 'taskStatus',
      taskStatus: { state: 'working', timestamp: Time.now.utc.iso8601 }
    })

    # Stream results
    YourAgentService.stream_process(message) do |chunk|
      artifact = A2A::Models::Artifact.new(
        name: 'response',
        parts: [A2A::Models::TextPart.new(text: chunk)],
        append: true
      )

      yield({
        type: 'artifactUpdate',
        artifact: artifact.to_h
      })
    end

    # Send completion
    yield({
      type: 'taskStatus',
      taskStatus: { state: 'completed', timestamp: Time.now.utc.iso8601 }
    })
  end
end

# Sinatra route for streaming
post '/stream' do
  content_type 'text/event-stream'

  stream :keep_open do |out|
    request_data = JSON.parse(request.body.read)
    params = request_data['params']

    server.handle_send_task_streaming(params) do |event|
      out << "data: #{event.to_json}\n\n"
    end

    out.close
  end
end
```

## See Also

- [API Overview](index.md)
- [Models Reference](models.md)
- [Protocol Reference](protocol.md)
- [Client Reference](client.md)
- [Quick Start Guide](../quickstart.md)
- [Server Examples](../examples/server.md)

---

[Back to API Reference](index.md) | [Back to Documentation Home](../index.md)
