# Client API Reference

Complete reference for the A2A client base class (`A2A::Client::Base`).

## Overview

The Client layer provides a base class for implementing A2A clients that consume A2A services. Clients discover agents, send tasks, manage task lifecycle, and handle streaming responses.

**Source:** `lib/a2a/client/base.rb`

## Table of Contents

- [Class: A2A::Client::Base](#class-a2aclientbase)
  - [Constructor](#constructor)
  - [Instance Attributes](#instance-attributes)
  - [Instance Methods](#instance-methods)
    - [Agent Discovery](#agent-discovery)
    - [Task Management](#task-management)
    - [Push Notifications](#push-notifications)
- [Implementation Guide](#implementation-guide)
- [Usage Examples](#usage-examples)

---

## Class: A2A::Client::Base

Base class for A2A clients. An A2A client consumes A2A services by sending requests to an A2A server.

This is an abstract base class that defines the interface for A2A clients. Subclasses must implement the abstract methods to provide concrete HTTP/network implementations.

### Constructor

```ruby
A2A::Client::Base.new(agent_url)
```

**Parameters:**

- `agent_url` (String, required) - The base URL of the agent's A2A endpoint

**Returns:** `Client::Base` instance

**Example:**

```ruby
class MyA2AClient < A2A::Client::Base
  # Implementation here
end

client = MyA2AClient.new('https://agent.example.com')
```

---

### Instance Attributes

#### `#agent_url`

Returns the agent's base URL.

**Returns:** `String`

**Example:**

```ruby
client.agent_url  # => "https://agent.example.com"
```

#### `#agent_card`

Returns the discovered agent card (nil until `discover` is called).

**Returns:** `A2A::Models::AgentCard` or `nil`

**Example:**

```ruby
client.discover
client.agent_card  # => #<A2A::Models::AgentCard:...>
client.agent_card.name  # => "DataAnalyzer"
```

---

### Instance Methods

#### Agent Discovery

##### `#discover`

Discover the agent by fetching its AgentCard from `/.well-known/agent.json`.

**Returns:** Implementation-defined (typically the AgentCard)

**Raises:** `NotImplementedError` - Subclasses must implement this method

**Example Implementation:**

```ruby
class MyA2AClient < A2A::Client::Base
  def discover
    require 'net/http'
    require 'json'

    uri = URI.join(@agent_url, '/.well-known/agent.json')
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      card_data = JSON.parse(response.body)
      @agent_card = A2A::Models::AgentCard.from_hash(card_data)
    else
      raise "Failed to discover agent: #{response.code}"
    end

    @agent_card
  end
end
```

**Usage:**

```ruby
client = MyA2AClient.new('https://agent.example.com')
agent_card = client.discover

puts "Agent: #{agent_card.name}"
puts "Version: #{agent_card.version}"
puts "Capabilities:"
puts "  - Streaming: #{agent_card.capabilities.streaming?}"
puts "  - Push Notifications: #{agent_card.capabilities.push_notifications?}"

agent_card.skills.each do |skill|
  puts "Skill: #{skill.name} - #{skill.description}"
end
```

---

#### Task Management

##### `#send_task(task_id:, message:, session_id: nil)`

Send a task to the agent.

**Parameters:**

- `task_id` (String, required) - Unique task identifier
- `message` (A2A::Models::Message, required) - The message to send
- `session_id` (String, optional) - Optional session ID for multi-turn conversations

**Returns:** `A2A::Models::Task` - The task response

**Raises:** `NotImplementedError` - Subclasses must implement this method

**Example Implementation:**

```ruby
class MyA2AClient < A2A::Client::Base
  def send_task(task_id:, message:, session_id: nil)
    require 'net/http'
    require 'json'

    # Build request
    request = A2A::Protocol::Request.new(
      method: 'tasks/send',
      params: {
        taskId: task_id,
        sessionId: session_id,
        message: message.to_h
      }.compact,
      id: generate_request_id
    )

    # Send HTTP request
    uri = URI(@agent_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    http_request = Net::HTTP::Post.new('/', 'Content-Type' => 'application/json')
    http_request.body = request.to_json

    http_response = http.request(http_request)

    # Parse response
    response = A2A::Protocol::Response.from_hash(JSON.parse(http_response.body))

    if response.success?
      A2A::Models::Task.from_hash(response.result)
    else
      raise "Task failed: #{response.error}"
    end
  end

  private

  def generate_request_id
    @request_counter ||= 0
    @request_counter += 1
  end
end
```

**Usage:**

```ruby
# Create a message
message = A2A::Models::Message.text(
  role: 'user',
  text: 'Analyze this sales data and provide insights.'
)

# Send the task
task = client.send_task(
  task_id: SecureRandom.uuid,
  message: message,
  session_id: 'session-123'
)

puts "Task ID: #{task.id}"
puts "State: #{task.state}"
puts "Session: #{task.session_id}"
```

---

##### `#send_task_streaming(task_id:, message:, session_id: nil, &block)`

Send a task with streaming support. The block is called with each event as the task progresses.

**Parameters:**

- `task_id` (String, required) - Unique task identifier
- `message` (A2A::Models::Message, required) - The message to send
- `session_id` (String, optional) - Optional session ID
- `block` (Block, required) - Block that receives streaming events

**Yields:** Event objects (task status updates and artifact updates)

**Returns:** Implementation-defined

**Raises:** `NotImplementedError` - Subclasses must implement this method

**Example Implementation:**

```ruby
class MyA2AClient < A2A::Client::Base
  def send_task_streaming(task_id:, message:, session_id: nil, &block)
    require 'net/http'
    require 'json'

    # Build request
    request = A2A::Protocol::Request.new(
      method: 'tasks/sendSubscribe',
      params: {
        taskId: task_id,
        sessionId: session_id,
        message: message.to_h
      }.compact,
      id: generate_request_id
    )

    # Send HTTP request with streaming
    uri = URI(@agent_url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http_request = Net::HTTP::Post.new('/', 'Content-Type' => 'application/json')
      http_request.body = request.to_json

      http.request(http_request) do |response|
        response.read_body do |chunk|
          # Parse Server-Sent Events
          chunk.split("\n\n").each do |event_data|
            next if event_data.strip.empty?

            # Parse event
            event = parse_sse_event(event_data)
            yield event if event
          end
        end
      end
    end
  end

  private

  def parse_sse_event(event_data)
    lines = event_data.split("\n")
    data_line = lines.find { |l| l.start_with?('data: ') }
    return nil unless data_line

    json_data = data_line.sub('data: ', '')
    JSON.parse(json_data)
  end
end
```

**Usage:**

```ruby
message = A2A::Models::Message.text(
  role: 'user',
  text: 'Generate a detailed report on Q4 sales.'
)

client.send_task_streaming(
  task_id: SecureRandom.uuid,
  message: message
) do |event|
  case event['type']
  when 'taskStatus'
    status = A2A::Models::TaskStatus.from_hash(event['taskStatus'])
    puts "Status: #{status.state}"

  when 'artifactUpdate'
    artifact = A2A::Models::Artifact.from_hash(event['artifact'])
    puts "Artifact: #{artifact.name}"
    artifact.parts.each do |part|
      puts "  #{part.type}: #{part.text}" if part.is_a?(A2A::Models::TextPart)
    end
  end
end
```

---

##### `#get_task(task_id:)`

Get the current status of a task.

**Parameters:**

- `task_id` (String, required) - The task identifier

**Returns:** `A2A::Models::Task` - The task

**Raises:** `NotImplementedError` - Subclasses must implement this method

**Example Implementation:**

```ruby
class MyA2AClient < A2A::Client::Base
  def get_task(task_id:)
    require 'net/http'
    require 'json'

    request = A2A::Protocol::Request.new(
      method: 'tasks/get',
      params: { taskId: task_id },
      id: generate_request_id
    )

    uri = URI(@agent_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    http_request = Net::HTTP::Post.new('/', 'Content-Type' => 'application/json')
    http_request.body = request.to_json

    http_response = http.request(http_request)
    response = A2A::Protocol::Response.from_hash(JSON.parse(http_response.body))

    if response.success?
      A2A::Models::Task.from_hash(response.result)
    else
      raise A2A::TaskNotFoundError.new if response.error['code'] == -32001
      raise "Failed to get task: #{response.error}"
    end
  end
end
```

**Usage:**

```ruby
task = client.get_task(task_id: 'task-123')

puts "Task: #{task.id}"
puts "State: #{task.state}"
puts "Submitted at: #{task.status.timestamp}"

if task.state.completed?
  puts "Task completed!"
  task.artifacts.each do |artifact|
    puts "Artifact: #{artifact.name}"
  end
elsif task.state.failed?
  puts "Task failed: #{task.status.message}"
end
```

---

##### `#cancel_task(task_id:)`

Cancel a task.

**Parameters:**

- `task_id` (String, required) - The task identifier

**Returns:** `A2A::Models::Task` - The canceled task

**Raises:**
  - `NotImplementedError` - Subclasses must implement this method
  - `A2A::TaskNotCancelableError` - If the task cannot be canceled

**Example Implementation:**

```ruby
class MyA2AClient < A2A::Client::Base
  def cancel_task(task_id:)
    require 'net/http'
    require 'json'

    request = A2A::Protocol::Request.new(
      method: 'tasks/cancel',
      params: { taskId: task_id },
      id: generate_request_id
    )

    uri = URI(@agent_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    http_request = Net::HTTP::Post.new('/', 'Content-Type' => 'application/json')
    http_request.body = request.to_json

    http_response = http.request(http_request)
    response = A2A::Protocol::Response.from_hash(JSON.parse(http_response.body))

    if response.success?
      A2A::Models::Task.from_hash(response.result)
    else
      case response.error['code']
      when -32001
        raise A2A::TaskNotFoundError.new
      when -32002
        raise A2A::TaskNotCancelableError.new
      else
        raise "Failed to cancel task: #{response.error}"
      end
    end
  end
end
```

**Usage:**

```ruby
begin
  task = client.cancel_task(task_id: 'task-123')
  puts "Task canceled: #{task.state.canceled?}"
rescue A2A::TaskNotCancelableError
  puts "Task cannot be canceled (already completed or failed)"
rescue A2A::TaskNotFoundError
  puts "Task not found"
end
```

---

#### Push Notifications

##### `#set_push_notification(task_id:, config:)`

Set push notification configuration for a task.

**Parameters:**

- `task_id` (String, required) - The task identifier
- `config` (A2A::Models::PushNotificationConfig, required) - The push notification configuration

**Returns:** Implementation-defined

**Raises:**
  - `NotImplementedError` - Subclasses must implement this method
  - `A2A::PushNotificationNotSupportedError` - If push notifications are not supported

**Example Implementation:**

```ruby
class MyA2AClient < A2A::Client::Base
  def set_push_notification(task_id:, config:)
    require 'net/http'
    require 'json'

    request = A2A::Protocol::Request.new(
      method: 'tasks/pushNotification/set',
      params: {
        taskId: task_id,
        config: config.to_h
      },
      id: generate_request_id
    )

    uri = URI(@agent_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    http_request = Net::HTTP::Post.new('/', 'Content-Type' => 'application/json')
    http_request.body = request.to_json

    http_response = http.request(http_request)
    response = A2A::Protocol::Response.from_hash(JSON.parse(http_response.body))

    unless response.success?
      raise A2A::PushNotificationNotSupportedError.new if response.error['code'] == -32003
      raise "Failed to set push notification: #{response.error}"
    end

    true
  end
end
```

**Usage:**

```ruby
config = A2A::Models::PushNotificationConfig.new(
  url: 'https://myclient.example.com/notifications',
  token: 'secret-token-123'
)

begin
  client.set_push_notification(task_id: 'task-123', config: config)
  puts "Push notifications configured"
rescue A2A::PushNotificationNotSupportedError
  puts "Agent doesn't support push notifications"
end
```

---

##### `#get_push_notification(task_id:)`

Get push notification configuration for a task.

**Parameters:**

- `task_id` (String, required) - The task identifier

**Returns:** `A2A::Models::PushNotificationConfig` - The configuration

**Raises:**
  - `NotImplementedError` - Subclasses must implement this method
  - `A2A::PushNotificationNotSupportedError` - If push notifications are not supported

**Example Implementation:**

```ruby
class MyA2AClient < A2A::Client::Base
  def get_push_notification(task_id:)
    require 'net/http'
    require 'json'

    request = A2A::Protocol::Request.new(
      method: 'tasks/pushNotification/get',
      params: { taskId: task_id },
      id: generate_request_id
    )

    uri = URI(@agent_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    http_request = Net::HTTP::Post.new('/', 'Content-Type' => 'application/json')
    http_request.body = request.to_json

    http_response = http.request(http_request)
    response = A2A::Protocol::Response.from_hash(JSON.parse(http_response.body))

    if response.success?
      A2A::Models::PushNotificationConfig.from_hash(response.result)
    else
      raise A2A::PushNotificationNotSupportedError.new if response.error['code'] == -32003
      raise "Failed to get push notification config: #{response.error}"
    end
  end
end
```

**Usage:**

```ruby
begin
  config = client.get_push_notification(task_id: 'task-123')
  puts "Notification URL: #{config.url}"
  puts "Token configured: #{!config.token.nil?}"
rescue A2A::PushNotificationNotSupportedError
  puts "Push notifications not supported"
end
```

---

## Implementation Guide

### Creating a Custom Client

To create a working A2A client, you must:

1. Subclass `A2A::Client::Base`
2. Implement all abstract methods
3. Handle HTTP/network communication
4. Parse JSON-RPC requests and responses
5. Handle errors appropriately

### Minimal Implementation

```ruby
require 'a2a'
require 'net/http'
require 'json'

class SimpleA2AClient < A2A::Client::Base
  def discover
    uri = URI.join(@agent_url, '/.well-known/agent.json')
    response = Net::HTTP.get_response(uri)
    @agent_card = A2A::Models::AgentCard.from_hash(JSON.parse(response.body))
  end

  def send_task(task_id:, message:, session_id: nil)
    response = make_request('tasks/send', {
      taskId: task_id,
      sessionId: session_id,
      message: message.to_h
    }.compact)

    A2A::Models::Task.from_hash(response.result)
  end

  def send_task_streaming(task_id:, message:, session_id: nil, &block)
    raise A2A::UnsupportedOperationError.new
  end

  def get_task(task_id:)
    response = make_request('tasks/get', { taskId: task_id })
    A2A::Models::Task.from_hash(response.result)
  end

  def cancel_task(task_id:)
    response = make_request('tasks/cancel', { taskId: task_id })
    A2A::Models::Task.from_hash(response.result)
  end

  def set_push_notification(task_id:, config:)
    make_request('tasks/pushNotification/set', {
      taskId: task_id,
      config: config.to_h
    })
    true
  end

  def get_push_notification(task_id:)
    response = make_request('tasks/pushNotification/get', { taskId: task_id })
    A2A::Models::PushNotificationConfig.from_hash(response.result)
  end

  private

  def make_request(method, params)
    request = A2A::Protocol::Request.new(
      method: method,
      params: params,
      id: next_id
    )

    uri = URI(@agent_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    http_request = Net::HTTP::Post.new('/', 'Content-Type' => 'application/json')
    http_request.body = request.to_json

    http_response = http.request(http_request)
    response = A2A::Protocol::Response.from_hash(JSON.parse(http_response.body))

    raise_error(response.error) unless response.success?

    response
  end

  def next_id
    @counter ||= 0
    @counter += 1
  end

  def raise_error(error)
    case error['code']
    when -32001 then raise A2A::TaskNotFoundError.new
    when -32002 then raise A2A::TaskNotCancelableError.new
    when -32003 then raise A2A::PushNotificationNotSupportedError.new
    when -32004 then raise A2A::UnsupportedOperationError.new
    else raise A2A::Error, error['message']
    end
  end
end
```

---

## Usage Examples

### Complete Workflow

```ruby
# Initialize client
client = SimpleA2AClient.new('https://agent.example.com')

# Discover agent capabilities
agent_card = client.discover
puts "Connected to: #{agent_card.name} v#{agent_card.version}"
puts "Supports streaming: #{agent_card.capabilities.streaming?}"

# Check agent skills
skill = agent_card.skills.first
puts "First skill: #{skill.name}"

# Send a task
message = A2A::Models::Message.text(
  role: 'user',
  text: 'Analyze the attached sales data'
)

task_id = SecureRandom.uuid
task = client.send_task(task_id: task_id, message: message)

# Poll for completion
loop do
  sleep 2
  task = client.get_task(task_id: task_id)

  puts "Task state: #{task.state}"

  break if task.state.terminal?
end

# Get results
if task.state.completed?
  puts "Task completed successfully!"
  task.artifacts.each do |artifact|
    puts "Artifact: #{artifact.name}"
    artifact.parts.each do |part|
      puts part.text if part.is_a?(A2A::Models::TextPart)
    end
  end
else
  puts "Task failed: #{task.status.message}"
end
```

### Multi-turn Conversation

```ruby
session_id = SecureRandom.uuid

# First turn
message1 = A2A::Models::Message.text(
  role: 'user',
  text: 'What were our top 5 products last quarter?'
)

task1 = client.send_task(
  task_id: SecureRandom.uuid,
  message: message1,
  session_id: session_id
)

# Wait for completion...

# Second turn (follow-up question)
message2 = A2A::Models::Message.text(
  role: 'user',
  text: 'Can you break down the sales by region for those products?'
)

task2 = client.send_task(
  task_id: SecureRandom.uuid,
  message: message2,
  session_id: session_id  # Same session
)
```

## See Also

- [API Overview](index.md)
- [Models Reference](models.md)
- [Protocol Reference](protocol.md)
- [Server Reference](server.md)
- [Quick Start Guide](../quickstart.md)
- [Client Examples](../examples/client.md)

---

[Back to API Reference](index.md) | [Back to Documentation Home](../index.md)
