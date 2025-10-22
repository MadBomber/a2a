# Building A2A HTTP Clients

This guide provides complete, production-ready examples for building A2A HTTP clients that can consume A2A-compatible agent services.

## Table of Contents

- [Overview](#overview)
- [Client Architecture](#client-architecture)
- [Simple HTTP Client with Faraday](#simple-http-client-with-faraday)
- [Complete Production Client](#complete-production-client)
- [Net::HTTP Implementation](#nethttp-implementation)
- [Streaming with Server-Sent Events](#streaming-with-server-sent-events)
- [Error Handling and Retries](#error-handling-and-retries)
- [Push Notifications](#push-notifications)
- [Authentication](#authentication)
- [Complete Working Examples](#complete-working-examples)
- [Testing Clients](#testing-clients)
- [Best Practices](#best-practices)

## Overview

An A2A client is responsible for:

1. **Discovering agents** via AgentCard (/.well-known/agent.json)
2. **Sending tasks** to agents with messages
3. **Receiving responses** synchronously or via streaming
4. **Polling for task status** when needed
5. **Canceling tasks** that are no longer needed
6. **Handling errors** gracefully with retries
7. **Managing authentication** when required

### Key Responsibilities

```
┌────────────────────────────────────────────────┐
│           A2A HTTP Client                      │
├────────────────────────────────────────────────┤
│                                                │
│  1. discover()                                 │
│     └─> GET /.well-known/agent.json          │
│                                                │
│  2. send_task(task_id, message)               │
│     └─> POST /a2a [tasks/send]                │
│                                                │
│  3. send_task_streaming(task_id, message)     │
│     └─> POST /a2a [tasks/sendSubscribe]       │
│         └─> Listen to SSE stream              │
│                                                │
│  4. get_task(task_id)                         │
│     └─> POST /a2a [tasks/get]                 │
│                                                │
│  5. cancel_task(task_id)                      │
│     └─> POST /a2a [tasks/cancel]              │
│                                                │
│  6. set_push_notification(task_id, config)    │
│     └─> POST /a2a [tasks/pushNotification/set]│
│                                                │
└────────────────────────────────────────────────┘
```

## Client Architecture

The A2A gem provides `A2A::Client::Base` as a foundation for building clients. You subclass it and implement the HTTP transport layer.

### Base Class Methods

```ruby
class A2A::Client::Base
  # Initialize with agent URL
  def initialize(agent_url)

  # Discover agent capabilities
  def discover() # => A2A::Models::AgentCard

  # Send task synchronously
  def send_task(task_id:, message:, session_id: nil) # => A2A::Models::Task

  # Send task with streaming
  def send_task_streaming(task_id:, message:, session_id: nil, &block)

  # Get task status
  def get_task(task_id:) # => A2A::Models::Task

  # Cancel a task
  def cancel_task(task_id:) # => A2A::Models::Task

  # Configure push notifications
  def set_push_notification(task_id:, config:)

  # Get push notification config
  def get_push_notification(task_id:) # => A2A::Models::PushNotificationConfig
end
```

## Simple HTTP Client with Faraday

Let's start with a simple client implementation using Faraday.

### Example 1: Basic Faraday Client

```ruby
require 'a2a'
require 'faraday'
require 'json'
require 'securerandom'
require 'debug_me'

class SimpleA2AClient < A2A::Client::Base
  def initialize(agent_url, timeout: 30)
    super(agent_url)
    @timeout = timeout
    @conn = build_connection
  end

  def discover
    debug_me "Discovering agent at #{agent_url}"

    response = @conn.get('/.well-known/agent.json')

    unless response.success?
      raise A2A::InternalError.new(
        data: { reason: "Failed to fetch AgentCard", status: response.status }
      )
    end

    agent_data = JSON.parse(response.body, symbolize_names: true)
    @agent_card = A2A::Models::AgentCard.from_hash(agent_data)

    debug_me "Discovered agent: #{@agent_card.name} v#{@agent_card.version}"
    @agent_card

  rescue Faraday::Error => e
    debug_me "Network error during discovery: #{e.message}"
    raise A2A::InternalError.new(data: { reason: e.message })
  end

  def send_task(task_id:, message:, session_id: nil)
    debug_me "Sending task #{task_id}"

    request = build_json_rpc_request(
      method: "tasks/send",
      params: {
        taskId: task_id,
        message: message.to_h,
        sessionId: session_id
      }.compact
    )

    response = post_json_rpc(request)
    task = A2A::Models::Task.from_hash(response.result)

    debug_me "Task submitted: #{task.state}"
    task
  end

  def get_task(task_id:)
    debug_me "Getting task #{task_id}"

    request = build_json_rpc_request(
      method: "tasks/get",
      params: { taskId: task_id }
    )

    response = post_json_rpc(request)
    A2A::Models::Task.from_hash(response.result)
  end

  def cancel_task(task_id:)
    debug_me "Canceling task #{task_id}"

    request = build_json_rpc_request(
      method: "tasks/cancel",
      params: { taskId: task_id }
    )

    response = post_json_rpc(request)
    A2A::Models::Task.from_hash(response.result)
  end

  private

  def build_connection
    Faraday.new(url: agent_url) do |f|
      f.request :json
      f.response :json, content_type: /\bjson$/
      f.adapter Faraday.default_adapter
      f.options.timeout = @timeout
    end
  end

  def build_json_rpc_request(method:, params:)
    A2A::Protocol::Request.new(
      method: method,
      params: params,
      id: SecureRandom.uuid
    )
  end

  def post_json_rpc(request)
    debug_me "Sending JSON-RPC request: #{request.method}"

    response = @conn.post('/a2a') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = request.to_json
    end

    unless response.success?
      raise A2A::InternalError.new(
        data: { reason: "HTTP error", status: response.status }
      )
    end

    rpc_response = parse_json_rpc_response(response.body)

    unless rpc_response.success?
      handle_json_rpc_error(rpc_response.error)
    end

    rpc_response

  rescue Faraday::Error => e
    debug_me "Network error: #{e.message}"
    raise A2A::InternalError.new(data: { reason: e.message })
  end

  def parse_json_rpc_response(body)
    data = JSON.parse(body, symbolize_names: true)
    A2A::Protocol::Response.from_hash(data)
  rescue JSON::ParserError => e
    raise A2A::JSONParseError.new(data: { reason: e.message })
  end

  def handle_json_rpc_error(error)
    code = error[:code]
    message = error[:message]
    data = error[:data]

    case code
    when -32001 then raise A2A::TaskNotFoundError
    when -32002 then raise A2A::TaskNotCancelableError
    when -32003 then raise A2A::PushNotificationNotSupportedError
    when -32004 then raise A2A::UnsupportedOperationError
    when -32600 then raise A2A::InvalidRequestError.new(data: data)
    when -32601 then raise A2A::MethodNotFoundError.new(data: data)
    when -32602 then raise A2A::InvalidParamsError.new(data: data)
    when -32603 then raise A2A::InternalError.new(data: data)
    when -32700 then raise A2A::JSONParseError.new(data: data)
    else
      raise A2A::JSONRPCError.new(message, code: code, data: data)
    end
  end
end
```

### Example 2: Using the Simple Client

```ruby
require_relative 'simple_a2a_client'

# Create client
client = SimpleA2AClient.new('https://api.example.com')

# Discover agent
agent = client.discover
puts "Connected to: #{agent.name}"
puts "Capabilities: streaming=#{agent.capabilities.streaming?}"

# Send a task
message = A2A::Models::Message.text(
  role: "user",
  text: "Translate 'Hello' to Spanish"
)

task = client.send_task(
  task_id: SecureRandom.uuid,
  message: message
)

puts "Task submitted: #{task.id}"
puts "State: #{task.state}"

# Poll for completion
until task.state.terminal?
  sleep 1
  task = client.get_task(task_id: task.id)
  puts "State: #{task.state}"
end

# Get results
if task.state.completed?
  puts "Result: #{task.artifacts.first.parts.first.text}"
else
  puts "Task failed: #{task.status.message&.parts&.first&.text}"
end
```

## Complete Production Client

A production-ready client with connection pooling, retries, and comprehensive error handling.

### Example 3: Production Client Implementation

```ruby
require 'a2a'
require 'faraday'
require 'faraday/retry'
require 'json'
require 'securerandom'
require 'debug_me'

class ProductionA2AClient < A2A::Client::Base
  attr_reader :conn

  DEFAULT_TIMEOUT = 30
  DEFAULT_OPEN_TIMEOUT = 10
  DEFAULT_MAX_RETRIES = 3
  DEFAULT_RETRY_INTERVAL = 0.5

  def initialize(
    agent_url,
    timeout: DEFAULT_TIMEOUT,
    open_timeout: DEFAULT_OPEN_TIMEOUT,
    max_retries: DEFAULT_MAX_RETRIES,
    retry_interval: DEFAULT_RETRY_INTERVAL,
    headers: {}
  )
    super(agent_url)

    @timeout = timeout
    @open_timeout = open_timeout
    @max_retries = max_retries
    @retry_interval = retry_interval
    @custom_headers = headers
    @conn = build_connection
  end

  def discover
    debug_me "Discovering agent at #{agent_url}"

    response = with_error_handling do
      @conn.get('/.well-known/agent.json')
    end

    agent_data = JSON.parse(response.body, symbolize_names: true)
    @agent_card = A2A::Models::AgentCard.from_hash(agent_data)

    debug_me "Discovered: #{@agent_card.name} v#{@agent_card.version}"
    debug_me "Skills: #{@agent_card.skills.map(&:name).join(', ')}"

    @agent_card
  end

  def send_task(task_id:, message:, session_id: nil)
    debug_me { [:task_id, :session_id] }

    validate_message(message)

    request = build_request(
      "tasks/send",
      taskId: task_id,
      message: message.to_h,
      sessionId: session_id
    )

    response = execute_request(request)
    A2A::Models::Task.from_hash(response.result)
  end

  def send_task_streaming(task_id:, message:, session_id: nil, &block)
    raise NotImplementedError, "Streaming will be implemented in Example 7"
  end

  def get_task(task_id:)
    debug_me "Getting task: #{task_id}"

    request = build_request("tasks/get", taskId: task_id)
    response = execute_request(request)
    A2A::Models::Task.from_hash(response.result)
  end

  def cancel_task(task_id:)
    debug_me "Canceling task: #{task_id}"

    request = build_request("tasks/cancel", taskId: task_id)
    response = execute_request(request)
    A2A::Models::Task.from_hash(response.result)
  end

  def set_push_notification(task_id:, config:)
    debug_me "Setting push notification for task: #{task_id}"

    request = build_request(
      "tasks/pushNotification/set",
      taskId: task_id,
      pushNotificationConfig: config.to_h
    )

    execute_request(request)
    nil
  end

  def get_push_notification(task_id:)
    debug_me "Getting push notification config for task: #{task_id}"

    request = build_request("tasks/pushNotification/get", taskId: task_id)
    response = execute_request(request)
    A2A::Models::PushNotificationConfig.from_hash(response.result)
  end

  # Helper method for polling with exponential backoff
  def wait_for_task(task_id:, max_wait: 60, initial_interval: 1, max_interval: 10)
    debug_me "Waiting for task #{task_id} to complete"

    start_time = Time.now
    interval = initial_interval
    task = nil

    loop do
      task = get_task(task_id: task_id)

      if task.state.terminal?
        debug_me "Task completed in state: #{task.state}"
        return task
      end

      elapsed = Time.now - start_time
      if elapsed >= max_wait
        debug_me "Task timeout after #{elapsed}s"
        raise A2A::InternalError.new(
          data: { reason: "Task timeout", elapsed: elapsed }
        )
      end

      debug_me "Task state: #{task.state}, waiting #{interval}s"
      sleep interval

      # Exponential backoff
      interval = [interval * 1.5, max_interval].min
    end

    task
  end

  private

  def build_connection
    Faraday.new(url: agent_url) do |f|
      # Request/Response middleware
      f.request :json

      # Retry configuration
      f.request :retry,
                max: @max_retries,
                interval: @retry_interval,
                interval_randomness: 0.5,
                backoff_factor: 2,
                retry_statuses: [429, 500, 502, 503, 504],
                methods: [:get, :post],
                retry_block: lambda { |env, opts, retries, exc|
                  debug_me "Retry #{retries}/#{opts[:max]}: #{exc&.class}"
                }

      # Response middleware
      f.response :json, content_type: /\bjson$/
      f.response :raise_error

      # Adapter
      f.adapter Faraday.default_adapter

      # Timeouts
      f.options.timeout = @timeout
      f.options.open_timeout = @open_timeout
    end
  end

  def build_request(method, params)
    A2A::Protocol::Request.new(
      method: method,
      params: params.compact,
      id: SecureRandom.uuid
    )
  end

  def execute_request(request)
    debug_me "Executing: #{request.method}"

    response = with_error_handling do
      @conn.post('/a2a') do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers.merge!(@custom_headers)
        req.body = request.to_json
      end
    end

    parse_response(response)
  end

  def with_error_handling
    yield
  rescue Faraday::TimeoutError => e
    debug_me "Timeout error: #{e.message}"
    raise A2A::InternalError.new(data: { reason: "Request timeout" })
  rescue Faraday::ConnectionFailed => e
    debug_me "Connection failed: #{e.message}"
    raise A2A::InternalError.new(data: { reason: "Connection failed" })
  rescue Faraday::Error => e
    debug_me "Network error: #{e.message}"
    raise A2A::InternalError.new(data: { reason: e.message })
  end

  def parse_response(http_response)
    unless http_response.success?
      raise A2A::InternalError.new(
        data: { status: http_response.status, body: http_response.body }
      )
    end

    begin
      data = JSON.parse(http_response.body, symbolize_names: true)
      rpc_response = A2A::Protocol::Response.from_hash(data)
    rescue JSON::ParserError => e
      raise A2A::JSONParseError.new(data: { reason: e.message })
    end

    if rpc_response.success?
      rpc_response
    else
      handle_error(rpc_response.error)
    end
  end

  def handle_error(error)
    code = error[:code]
    message = error[:message]
    data = error[:data]

    debug_me "JSON-RPC error #{code}: #{message}"

    case code
    when -32001 then raise A2A::TaskNotFoundError
    when -32002 then raise A2A::TaskNotCancelableError
    when -32003 then raise A2A::PushNotificationNotSupportedError
    when -32004 then raise A2A::UnsupportedOperationError
    when -32600 then raise A2A::InvalidRequestError.new(data: data)
    when -32601 then raise A2A::MethodNotFoundError.new(data: data)
    when -32602 then raise A2A::InvalidParamsError.new(data: data)
    when -32603 then raise A2A::InternalError.new(data: data)
    when -32700 then raise A2A::JSONParseError.new(data: data)
    else
      raise A2A::JSONRPCError.new(message, code: code, data: data)
    end
  end

  def validate_message(message)
    unless message.is_a?(A2A::Models::Message)
      raise ArgumentError, "message must be an A2A::Models::Message"
    end

    unless message.parts.any?
      raise ArgumentError, "message must have at least one part"
    end
  end
end
```

### Example 4: Using the Production Client

```ruby
require_relative 'production_a2a_client'

# Create client with custom configuration
client = ProductionA2AClient.new(
  'https://api.example.com',
  timeout: 60,
  max_retries: 5,
  headers: {
    'Authorization' => 'Bearer your-api-key',
    'X-Client-Version' => '1.0.0'
  }
)

begin
  # Discover agent
  agent = client.discover

  # Send task
  message = A2A::Models::Message.text(
    role: "user",
    text: "Translate 'Hello, world!' to French"
  )

  task = client.send_task(
    task_id: SecureRandom.uuid,
    message: message
  )

  # Wait for completion with exponential backoff
  completed_task = client.wait_for_task(
    task_id: task.id,
    max_wait: 120
  )

  # Handle results
  if completed_task.state.completed?
    puts "Success!"
    completed_task.artifacts.each do |artifact|
      puts "Artifact: #{artifact.name}"
      artifact.parts.each do |part|
        case part
        when A2A::Models::TextPart
          puts "  Text: #{part.text}"
        when A2A::Models::DataPart
          puts "  Data: #{part.data.inspect}"
        end
      end
    end
  else
    puts "Task failed: #{completed_task.state}"
  end

rescue A2A::TaskNotFoundError
  puts "Task not found"
rescue A2A::InternalError => e
  puts "Internal error: #{e.message}"
  puts "Data: #{e.data}"
rescue A2A::JSONRPCError => e
  puts "Protocol error #{e.code}: #{e.message}"
end
```

## Net::HTTP Implementation

For environments without external dependencies, here's a pure Ruby implementation using Net::HTTP.

### Example 5: Net::HTTP Client

```ruby
require 'a2a'
require 'net/http'
require 'json'
require 'uri'
require 'securerandom'
require 'debug_me'

class NetHTTPClient < A2A::Client::Base
  def initialize(agent_url, timeout: 30)
    super(agent_url)
    @timeout = timeout
    @uri = URI.parse(agent_url)
  end

  def discover
    debug_me "Discovering agent at #{agent_url}"

    uri = URI.join(@uri, '/.well-known/agent.json')
    response = http_get(uri)

    agent_data = JSON.parse(response.body, symbolize_names: true)
    @agent_card = A2A::Models::AgentCard.from_hash(agent_data)

    debug_me "Discovered: #{@agent_card.name}"
    @agent_card
  end

  def send_task(task_id:, message:, session_id: nil)
    request = build_request(
      "tasks/send",
      taskId: task_id,
      message: message.to_h,
      sessionId: session_id
    )

    response = execute_json_rpc(request)
    A2A::Models::Task.from_hash(response.result)
  end

  def get_task(task_id:)
    request = build_request("tasks/get", taskId: task_id)
    response = execute_json_rpc(request)
    A2A::Models::Task.from_hash(response.result)
  end

  def cancel_task(task_id:)
    request = build_request("tasks/cancel", taskId: task_id)
    response = execute_json_rpc(request)
    A2A::Models::Task.from_hash(response.result)
  end

  private

  def http_get(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 10, read_timeout: @timeout) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Accept'] = 'application/json'

      http.request(request)
    end
  rescue => e
    debug_me "HTTP GET error: #{e.message}"
    raise A2A::InternalError.new(data: { reason: e.message })
  end

  def http_post(uri, body)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 10, read_timeout: @timeout) do |http|
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
      request.body = body

      http.request(request)
    end
  rescue => e
    debug_me "HTTP POST error: #{e.message}"
    raise A2A::InternalError.new(data: { reason: e.message })
  end

  def build_request(method, params)
    A2A::Protocol::Request.new(
      method: method,
      params: params.compact,
      id: SecureRandom.uuid
    )
  end

  def execute_json_rpc(request)
    uri = URI.join(@uri, '/a2a')
    response = http_post(uri, request.to_json)

    unless response.is_a?(Net::HTTPSuccess)
      raise A2A::InternalError.new(
        data: { status: response.code, message: response.message }
      )
    end

    begin
      data = JSON.parse(response.body, symbolize_names: true)
      rpc_response = A2A::Protocol::Response.from_hash(data)
    rescue JSON::ParserError => e
      raise A2A::JSONParseError.new(data: { reason: e.message })
    end

    if rpc_response.success?
      rpc_response
    else
      handle_error(rpc_response.error)
    end
  end

  def handle_error(error)
    code = error[:code]
    message = error[:message]
    data = error[:data]

    case code
    when -32001 then raise A2A::TaskNotFoundError
    when -32002 then raise A2A::TaskNotCancelableError
    when -32003 then raise A2A::PushNotificationNotSupportedError
    when -32004 then raise A2A::UnsupportedOperationError
    when -32602 then raise A2A::InvalidParamsError.new(data: data)
    when -32603 then raise A2A::InternalError.new(data: data)
    else
      raise A2A::JSONRPCError.new(message, code: code, data: data)
    end
  end
end
```

## Streaming with Server-Sent Events

Implementing real-time streaming for long-running tasks.

### Example 6: SSE Streaming Client

```ruby
require 'a2a'
require 'faraday'
require 'json'
require 'securerandom'
require 'debug_me'

class StreamingA2AClient < ProductionA2AClient
  def send_task_streaming(task_id:, message:, session_id: nil, &block)
    debug_me "Sending streaming task: #{task_id}"

    request = build_request(
      "tasks/sendSubscribe",
      taskId: task_id,
      message: message.to_h,
      sessionId: session_id
    )

    # Send initial request
    response = execute_request(request)
    initial_task = A2A::Models::Task.from_hash(response.result)

    # Connect to SSE stream
    stream_url = "#{agent_url}/a2a/stream/#{task_id}"
    listen_to_stream(stream_url, &block)

    initial_task
  end

  def resubscribe(task_id:, &block)
    debug_me "Resubscribing to task: #{task_id}"

    request = build_request("tasks/resubscribe", taskId: task_id)
    execute_request(request)

    stream_url = "#{agent_url}/a2a/stream/#{task_id}"
    listen_to_stream(stream_url, &block)
  end

  private

  def listen_to_stream(url, &block)
    debug_me "Connecting to SSE stream: #{url}"

    uri = URI.parse(url)
    buffer = ""

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', read_timeout: nil) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Accept'] = 'text/event-stream'
      request['Cache-Control'] = 'no-cache'

      http.request(request) do |response|
        unless response.is_a?(Net::HTTPSuccess)
          raise A2A::InternalError.new(
            data: { status: response.code, message: "Stream connection failed" }
          )
        end

        response.read_body do |chunk|
          buffer += chunk

          # Process complete events
          while buffer.include?("\n\n")
            event, buffer = buffer.split("\n\n", 2)
            process_sse_event(event, &block)
          end
        end
      end
    end

  rescue => e
    debug_me "Stream error: #{e.message}"
    raise A2A::InternalError.new(data: { reason: e.message })
  end

  def process_sse_event(event_text, &block)
    lines = event_text.split("\n")
    event_type = nil
    event_data = nil

    lines.each do |line|
      if line.start_with?('event:')
        event_type = line.sub('event:', '').strip
      elsif line.start_with?('data:')
        event_data = line.sub('data:', '').strip
      elsif line.start_with?(':')
        # Comment, ignore
      end
    end

    return unless event_data

    begin
      data = JSON.parse(event_data, symbolize_names: true)

      case event_type
      when 'taskStatus'
        task = A2A::Models::Task.from_hash(data[:task] || data)
        block.call(:status, task)

      when 'artifactUpdate'
        artifact = A2A::Models::Artifact.from_hash(data[:artifact] || data)
        block.call(:artifact, artifact)

      when 'taskComplete'
        task = A2A::Models::Task.from_hash(data[:task] || data)
        block.call(:complete, task)

      when 'error'
        error = data[:error]
        block.call(:error, error)

      else
        debug_me "Unknown event type: #{event_type}"
      end

    rescue JSON::ParserError => e
      debug_me "Failed to parse event data: #{e.message}"
    end
  end
end
```

### Example 7: Using Streaming Client

```ruby
require_relative 'streaming_a2a_client'

client = StreamingA2AClient.new('https://api.example.com')

message = A2A::Models::Message.text(
  role: "user",
  text: "Generate a long essay about AI"
)

task_id = SecureRandom.uuid
artifacts = []

begin
  client.send_task_streaming(
    task_id: task_id,
    message: message
  ) do |event_type, data|
    case event_type
    when :status
      puts "Status update: #{data.state}"

    when :artifact
      puts "Artifact chunk: #{data.name}"
      artifacts << data

      # Display streaming text
      data.parts.each do |part|
        print part.text if part.is_a?(A2A::Models::TextPart)
      end

    when :complete
      puts "\nTask completed!"
      puts "Final state: #{data.state}"

      if data.artifacts
        puts "Final artifacts: #{data.artifacts.length}"
      end

    when :error
      puts "Error: #{data[:message]}"
    end
  end

rescue A2A::JSONRPCError => e
  puts "Error: #{e.message} (code: #{e.code})"
end
```

## Error Handling and Retries

### Example 8: Retry Logic with Exponential Backoff

```ruby
require 'a2a'
require 'debug_me'

module A2AClientHelpers
  def with_retry(max_retries: 3, initial_wait: 1, max_wait: 30)
    retries = 0
    wait_time = initial_wait

    begin
      yield

    rescue A2A::InternalError, A2A::JSONRPCError => e
      retries += 1

      if retries <= max_retries
        debug_me "Retry #{retries}/#{max_retries} after #{wait_time}s (error: #{e.class})"
        sleep wait_time

        wait_time = [wait_time * 2, max_wait].min
        retry
      else
        debug_me "Max retries exceeded"
        raise
      end
    end
  end

  def safe_execute(operation_name)
    debug_me "Executing: #{operation_name}"

    with_retry do
      yield
    end

  rescue A2A::TaskNotFoundError
    debug_me "Task not found during: #{operation_name}"
    nil

  rescue A2A::JSONRPCError => e
    debug_me "Error during #{operation_name}: #{e.code} - #{e.message}"
    raise

  rescue StandardError => e
    debug_me "Unexpected error during #{operation_name}: #{e.class}"
    raise A2A::InternalError.new(data: { reason: e.message, backtrace: e.backtrace.first(5) })
  end
end

class RobustA2AClient < ProductionA2AClient
  include A2AClientHelpers

  def send_task(task_id:, message:, session_id: nil)
    safe_execute("send_task #{task_id}") do
      super
    end
  end

  def get_task(task_id:)
    safe_execute("get_task #{task_id}") do
      super
    end
  end
end
```

## Push Notifications

### Example 9: Configuring Push Notifications

```ruby
require_relative 'production_a2a_client'

client = ProductionA2AClient.new('https://api.example.com')

# Send task
message = A2A::Models::Message.text(role: "user", text: "Long running task")
task_id = SecureRandom.uuid
task = client.send_task(task_id: task_id, message: message)

# Configure push notification
notification_config = A2A::Models::PushNotificationConfig.new(
  url: "https://my-server.com/webhooks/a2a",
  token: "webhook-secret-token"
)

begin
  client.set_push_notification(
    task_id: task_id,
    config: notification_config
  )

  puts "Push notifications configured for task #{task_id}"

rescue A2A::PushNotificationNotSupportedError
  puts "Agent doesn't support push notifications, falling back to polling"

  # Fall back to polling
  loop do
    task = client.get_task(task_id: task_id)
    break if task.state.terminal?
    sleep 5
  end
end
```

## Authentication

### Example 10: Client with Bearer Token Authentication

```ruby
class AuthenticatedA2AClient < ProductionA2AClient
  def initialize(agent_url, api_key:, **options)
    @api_key = api_key

    super(
      agent_url,
      headers: { 'Authorization' => "Bearer #{api_key}" },
      **options
    )
  end

  def refresh_token(new_api_key)
    @api_key = new_api_key
    @custom_headers['Authorization'] = "Bearer #{new_api_key}"
  end
end

# Usage
client = AuthenticatedA2AClient.new(
  'https://api.example.com',
  api_key: ENV['A2A_API_KEY']
)

agent = client.discover
puts "Authenticated as: #{agent.name}"
```

## Complete Working Examples

### Example 11: Complete CLI Client

```ruby
#!/usr/bin/env ruby
require 'a2a'
require 'securerandom'
require 'optparse'
require 'debug_me'
require_relative 'production_a2a_client'

class A2ACLI
  def initialize(agent_url)
    @client = ProductionA2AClient.new(agent_url)
    @agent = nil
  end

  def run(command, **options)
    case command
    when 'discover'
      discover

    when 'send'
      send_task(options[:text], options[:session])

    when 'get'
      get_task(options[:task_id])

    when 'wait'
      wait_for_task(options[:task_id])

    when 'cancel'
      cancel_task(options[:task_id])

    else
      puts "Unknown command: #{command}"
      exit 1
    end
  end

  private

  def discover
    @agent = @client.discover

    puts "Agent: #{@agent.name}"
    puts "Version: #{@agent.version}"
    puts "URL: #{@agent.url}"
    puts "\nCapabilities:"
    puts "  Streaming: #{@agent.capabilities.streaming?}"
    puts "  Push Notifications: #{@agent.capabilities.push_notifications?}"
    puts "\nSkills:"
    @agent.skills.each do |skill|
      puts "  - #{skill.name}: #{skill.description}"
    end
  end

  def send_task(text, session_id = nil)
    message = A2A::Models::Message.text(role: "user", text: text)
    task_id = SecureRandom.uuid

    task = @client.send_task(
      task_id: task_id,
      message: message,
      session_id: session_id
    )

    puts "Task ID: #{task.id}"
    puts "State: #{task.state}"
    puts "Session: #{task.session_id}" if task.session_id
  end

  def get_task(task_id)
    task = @client.get_task(task_id: task_id)

    puts "Task ID: #{task.id}"
    puts "State: #{task.state}"

    if task.artifacts
      puts "\nArtifacts:"
      task.artifacts.each do |artifact|
        puts "  #{artifact.name}:"
        artifact.parts.each do |part|
          case part
          when A2A::Models::TextPart
            puts "    #{part.text}"
          when A2A::Models::DataPart
            puts "    Data: #{part.data.inspect}"
          end
        end
      end
    end
  end

  def wait_for_task(task_id)
    puts "Waiting for task #{task_id}..."

    task = @client.wait_for_task(task_id: task_id, max_wait: 300)

    puts "Task completed: #{task.state}"
    get_task(task_id)
  end

  def cancel_task(task_id)
    task = @client.cancel_task(task_id: task_id)
    puts "Task #{task_id} canceled: #{task.state}"
  end
end

# Parse command line
options = {}
command = ARGV.shift

OptionParser.new do |opts|
  opts.banner = "Usage: a2a_cli.rb COMMAND [options]"

  opts.on("--url URL", "Agent URL") { |v| options[:url] = v }
  opts.on("--text TEXT", "Message text") { |v| options[:text] = v }
  opts.on("--task-id ID", "Task ID") { |v| options[:task_id] = v }
  opts.on("--session ID", "Session ID") { |v| options[:session] = v }
end.parse!

agent_url = options[:url] || ENV['A2A_AGENT_URL'] || 'https://api.example.com'

cli = A2ACLI.new(agent_url)
cli.run(command, **options)
```

### Example 12: Multi-Turn Conversation Client

```ruby
require 'a2a'
require 'securerandom'
require_relative 'production_a2a_client'

class ConversationClient
  attr_reader :session_id, :client, :history

  def initialize(agent_url)
    @client = ProductionA2AClient.new(agent_url)
    @session_id = SecureRandom.uuid
    @history = []
  end

  def send(text)
    message = A2A::Models::Message.text(role: "user", text: text)
    task_id = SecureRandom.uuid

    # Send task in session
    task = @client.send_task(
      task_id: task_id,
      message: message,
      session_id: @session_id
    )

    # Wait for completion
    completed = @client.wait_for_task(task_id: task.id)

    # Store in history
    @history << { user: text, task: completed }

    # Extract response text
    extract_response(completed)
  end

  def print_history
    @history.each_with_index do |turn, i|
      puts "\n--- Turn #{i + 1} ---"
      puts "User: #{turn[:user]}"
      puts "Agent: #{extract_response(turn[:task])}"
    end
  end

  private

  def extract_response(task)
    return "Task failed: #{task.state}" unless task.state.completed?

    texts = []
    task.artifacts&.each do |artifact|
      artifact.parts.each do |part|
        texts << part.text if part.is_a?(A2A::Models::TextPart)
      end
    end

    texts.join("\n")
  end
end

# Usage
conv = ConversationClient.new('https://api.example.com')

puts "User: Translate 'Hello' to Spanish"
puts "Agent: #{conv.send("Translate 'Hello' to Spanish")}"

puts "\nUser: Now to French"
puts "Agent: #{conv.send("Now to French")}"

puts "\nUser: And to German"
puts "Agent: #{conv.send("And to German")}"

conv.print_history
```

## Testing Clients

### Example 13: Unit Testing Clients

```ruby
require 'a2a'
require 'minitest/autorun'
require 'webmock/minitest'

class TestA2AClient < Minitest::Test
  def setup
    @agent_url = 'https://test.example.com'
    @client = ProductionA2AClient.new(@agent_url)

    # Stub AgentCard
    stub_request(:get, "#{@agent_url}/.well-known/agent.json")
      .to_return(
        status: 200,
        body: agent_card_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def test_discover
    agent = @client.discover

    assert_equal "Test Agent", agent.name
    assert_equal "1.0.0", agent.version
    assert agent.capabilities.streaming?
  end

  def test_send_task
    task_id = "task-123"

    stub_request(:post, "#{@agent_url}/a2a")
      .with(body: hash_including(method: "tasks/send"))
      .to_return(
        status: 200,
        body: task_response_json(task_id, "completed"),
        headers: { 'Content-Type' => 'application/json' }
      )

    message = A2A::Models::Message.text(role: "user", text: "Hello")
    task = @client.send_task(task_id: task_id, message: message)

    assert_equal task_id, task.id
    assert task.state.completed?
  end

  def test_task_not_found_error
    stub_request(:post, "#{@agent_url}/a2a")
      .to_return(
        status: 200,
        body: error_response_json(-32001, "Task not found"),
        headers: { 'Content-Type' => 'application/json' }
      )

    assert_raises(A2A::TaskNotFoundError) do
      @client.get_task(task_id: "nonexistent")
    end
  end

  private

  def agent_card_json
    {
      name: "Test Agent",
      version: "1.0.0",
      url: @agent_url,
      capabilities: { streaming: true },
      skills: [{ id: "test", name: "Test", description: "Test skill" }]
    }.to_json
  end

  def task_response_json(task_id, state)
    {
      jsonrpc: "2.0",
      id: "1",
      result: {
        id: task_id,
        status: { state: state }
      }
    }.to_json
  end

  def error_response_json(code, message)
    {
      jsonrpc: "2.0",
      id: "1",
      error: { code: code, message: message }
    }.to_json
  end
end
```

## Best Practices

### 1. Always Discover First

```ruby
client = ProductionA2AClient.new(agent_url)
agent = client.discover

# Check capabilities before using them
if agent.capabilities.streaming?
  client.send_task_streaming(...)
else
  task = client.send_task(...)
  client.wait_for_task(task_id: task.id)
end
```

### 2. Use Unique Task IDs

```ruby
# Always generate unique IDs
task_id = SecureRandom.uuid

# Or include timestamp for debugging
task_id = "task-#{Time.now.to_i}-#{SecureRandom.hex(4)}"
```

### 3. Implement Proper Timeouts

```ruby
client = ProductionA2AClient.new(
  agent_url,
  timeout: 60,           # Read timeout
  open_timeout: 10       # Connection timeout
)
```

### 4. Handle All Error Cases

```ruby
begin
  task = client.send_task(...)
rescue A2A::TaskNotFoundError
  # Specific handling
rescue A2A::InvalidParamsError => e
  # Log validation errors
  puts "Invalid params: #{e.data}"
rescue A2A::JSONRPCError => e
  # Generic RPC error
  puts "Error #{e.code}: #{e.message}"
rescue StandardError => e
  # Unexpected errors
  puts "Unexpected: #{e.class}"
end
```

### 5. Use Connection Pooling

```ruby
# Reuse client instance
@client ||= ProductionA2AClient.new(agent_url)

# Don't create new client for each request
# BAD: ProductionA2AClient.new(url).send_task(...)
# GOOD: @client.send_task(...)
```

### 6. Log Everything

```ruby
require 'debug_me'

debug_me { [:task_id, :session_id, :state] }
debug_me "Sending task to #{agent_url}"
```

## Summary

This guide covered:

1. **Simple Clients** - Basic Faraday implementation
2. **Production Clients** - Full-featured with retries
3. **Net::HTTP** - Pure Ruby implementation
4. **Streaming** - SSE support for real-time updates
5. **Error Handling** - Comprehensive error management
6. **Authentication** - Bearer token support
7. **Testing** - Unit testing with WebMock
8. **Best Practices** - Production-ready patterns

### Next Steps

- **[Server Examples](server.md)** - Build A2A servers
- **[Basic Examples](basic.md)** - Review data models
- **[Examples Index](index.md)** - Return to overview

---

[Back to Examples Index](index.md) | [Back to Documentation Home](../index.md)
