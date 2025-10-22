# Building A2A HTTP Servers

This guide provides complete, production-ready examples for building A2A HTTP servers that expose agent services via the A2A protocol.

## Table of Contents

- [Overview](#overview)
- [Server Architecture](#server-architecture)
- [Simple Sinatra Server](#simple-sinatra-server)
- [Complete Production Server](#complete-production-server)
- [Task Storage and Management](#task-storage-and-management)
- [Streaming with SSE](#streaming-with-sse)
- [Background Job Processing](#background-job-processing)
- [Authentication and Authorization](#authentication-and-authorization)
- [Complete Working Examples](#complete-working-examples)
- [Testing Servers](#testing-servers)
- [Production Deployment](#production-deployment)
- [Best Practices](#best-practices)

## Overview

An A2A server exposes an HTTP endpoint that implements the A2A protocol, allowing clients to:

1. **Discover the agent** via AgentCard at `/.well-known/agent.json`
2. **Submit tasks** for processing
3. **Get task status** and results
4. **Cancel tasks** that are no longer needed
5. **Stream updates** via Server-Sent Events (SSE)
6. **Receive push notification configs** for webhook-based updates

### Key Responsibilities

```
┌────────────────────────────────────────────────┐
│           A2A HTTP Server                      │
├────────────────────────────────────────────────┤
│                                                │
│  GET /.well-known/agent.json                  │
│    └─> Return AgentCard                       │
│                                                │
│  POST /a2a                                     │
│    ├─> tasks/send                             │
│    │   └─> Create and process task            │
│    ├─> tasks/sendSubscribe                    │
│    │   └─> Create task and stream updates     │
│    ├─> tasks/get                              │
│    │   └─> Return task status                 │
│    ├─> tasks/cancel                           │
│    │   └─> Cancel task                        │
│    ├─> tasks/pushNotification/set             │
│    │   └─> Configure push notifications       │
│    └─> tasks/pushNotification/get             │
│        └─> Get notification config            │
│                                                │
│  GET /a2a/stream/:task_id (optional)          │
│    └─> Stream task updates via SSE            │
│                                                │
└────────────────────────────────────────────────┘
```

## Server Architecture

The A2A gem provides `A2A::Server::Base` as a foundation. You subclass it and implement the HTTP server layer.

### Base Class Methods

```ruby
class A2A::Server::Base
  # Initialize with AgentCard
  def initialize(agent_card)

  # Handle incoming JSON-RPC request
  def handle_request(request) # => Hash

  # Handle tasks/send
  def handle_send_task(params) # => A2A::Models::Task

  # Handle tasks/sendSubscribe (streaming)
  def handle_send_task_streaming(params, &block)

  # Handle tasks/get
  def handle_get_task(params) # => A2A::Models::Task

  # Handle tasks/cancel
  def handle_cancel_task(params) # => A2A::Models::Task

  # Handle tasks/pushNotification/set
  def handle_set_push_notification(params)

  # Handle tasks/pushNotification/get
  def handle_get_push_notification(params) # => A2A::Models::PushNotificationConfig

  # Handle tasks/resubscribe
  def handle_resubscribe(params, &block)
end
```

## Simple Sinatra Server

Let's start with a basic A2A server using Sinatra.

### Example 1: Basic Sinatra Server

```ruby
require 'sinatra/base'
require 'a2a'
require 'json'
require 'securerandom'
require 'debug_me'

class SimpleA2AServer < A2A::Server::Base
  attr_reader :tasks

  def initialize(agent_card)
    super(agent_card)
    @tasks = {}
  end

  def handle_request(request)
    debug_me "Handling request: #{request[:method]}"

    case request[:method]
    when 'tasks/send'
      task = handle_send_task(request[:params])
      { result: task.to_h }

    when 'tasks/get'
      task = handle_get_task(request[:params])
      { result: task.to_h }

    when 'tasks/cancel'
      task = handle_cancel_task(request[:params])
      { result: task.to_h }

    else
      {
        error: {
          code: -32601,
          message: "Method not found: #{request[:method]}"
        }
      }
    end
  end

  def handle_send_task(params)
    task_id = params[:taskId] || params['taskId']
    message_data = params[:message] || params['message']

    raise A2A::InvalidParamsError unless task_id && message_data

    message = A2A::Models::Message.from_hash(message_data)

    # Process task immediately (simplified)
    result_text = process_message(message)

    task = A2A::Models::Task.new(
      id: task_id,
      session_id: params[:sessionId] || params['sessionId'],
      status: { state: 'completed' },
      artifacts: [
        A2A::Models::Artifact.new(
          name: 'Response',
          parts: [A2A::Models::TextPart.new(text: result_text)]
        )
      ]
    )

    @tasks[task_id] = task
    debug_me "Task #{task_id} completed"
    task
  end

  def handle_get_task(params)
    task_id = params[:taskId] || params['taskId']
    task = @tasks[task_id]

    raise A2A::TaskNotFoundError unless task

    task
  end

  def handle_cancel_task(params)
    task_id = params[:taskId] || params['taskId']
    task = @tasks[task_id]

    raise A2A::TaskNotFoundError unless task
    raise A2A::TaskNotCancelableError if task.state.terminal?

    canceled_task = A2A::Models::Task.new(
      id: task.id,
      session_id: task.session_id,
      status: { state: 'canceled' }
    )

    @tasks[task_id] = canceled_task
    canceled_task
  end

  private

  def process_message(message)
    # Simple echo processor
    text = message.parts.first.text
    "Echo: #{text}"
  end
end

# Sinatra app
class A2AApp < Sinatra::Base
  def initialize
    super

    # Create agent card
    agent_card = A2A::Models::AgentCard.new(
      name: "Simple Echo Agent",
      url: "http://localhost:4567",
      version: "1.0.0",
      capabilities: {
        streaming: false,
        push_notifications: false
      },
      skills: [
        {
          id: "echo",
          name: "Echo",
          description: "Echoes back your message"
        }
      ]
    )

    @server = SimpleA2AServer.new(agent_card)
  end

  # Serve AgentCard
  get '/.well-known/agent.json' do
    content_type :json
    @server.agent_card.to_json
  end

  # Handle JSON-RPC requests
  post '/a2a' do
    content_type :json

    begin
      request_data = JSON.parse(request.body.read, symbolize_names: true)

      response = @server.handle_request(request_data)

      {
        jsonrpc: '2.0',
        id: request_data[:id],
        **response
      }.to_json

    rescue A2A::JSONRPCError => e
      {
        jsonrpc: '2.0',
        id: request_data&.dig(:id),
        error: {
          code: e.code,
          message: e.message,
          data: e.data
        }
      }.to_json

    rescue JSON::ParserError
      {
        jsonrpc: '2.0',
        id: nil,
        error: {
          code: -32700,
          message: 'Invalid JSON'
        }
      }.to_json
    end
  end
end

# Run the server
if __FILE__ == $0
  A2AApp.run! port: 4567
end
```

## Complete Production Server

A full-featured server with proper task management, background processing, and error handling.

### Example 2: Production Server Implementation

```ruby
require 'sinatra/base'
require 'a2a'
require 'json'
require 'securerandom'
require 'thread'
require 'debug_me'

class ProductionA2AServer < A2A::Server::Base
  attr_reader :tasks, :push_configs, :sessions

  def initialize(agent_card, processor:)
    super(agent_card)

    @processor = processor
    @tasks = Concurrent::Hash.new
    @push_configs = Concurrent::Hash.new
    @sessions = Concurrent::Hash.new
    @task_queue = Queue.new
    @streaming_clients = Concurrent::Hash.new

    start_background_workers
  end

  def handle_request(request)
    validate_request(request)

    case request[:method]
    when 'tasks/send'
      task = handle_send_task(request[:params])
      { result: task.to_h }

    when 'tasks/sendSubscribe'
      task = handle_send_task_streaming(request[:params])
      { result: task.to_h }

    when 'tasks/get'
      task = handle_get_task(request[:params])
      { result: task.to_h }

    when 'tasks/cancel'
      task = handle_cancel_task(request[:params])
      { result: task.to_h }

    when 'tasks/pushNotification/set'
      handle_set_push_notification(request[:params])
      { result: {} }

    when 'tasks/pushNotification/get'
      config = handle_get_push_notification(request[:params])
      { result: config.to_h }

    when 'tasks/resubscribe'
      handle_resubscribe(request[:params])
      { result: {} }

    else
      raise A2A::MethodNotFoundError
    end

  rescue A2A::JSONRPCError => e
    {
      error: {
        code: e.code,
        message: e.message,
        data: e.data
      }
    }
  end

  def handle_send_task(params)
    task_id, message, session_id = extract_task_params(params)

    task = create_task(task_id, message, session_id, streaming: false)
    @tasks[task_id] = task

    # Queue for background processing
    @task_queue << task_id

    debug_me "Task #{task_id} queued"
    task
  end

  def handle_send_task_streaming(params)
    task_id, message, session_id = extract_task_params(params)

    task = create_task(task_id, message, session_id, streaming: true)
    @tasks[task_id] = task

    # Queue for background processing
    @task_queue << task_id

    debug_me "Streaming task #{task_id} queued"
    task
  end

  def handle_get_task(params)
    task_id = params[:taskId] || params['taskId']
    task = @tasks[task_id]

    raise A2A::TaskNotFoundError unless task

    task
  end

  def handle_cancel_task(params)
    task_id = params[:taskId] || params['taskId']
    task = @tasks[task_id]

    raise A2A::TaskNotFoundError unless task
    raise A2A::TaskNotCancelableError if task.state.terminal?

    update_task_state(task_id, 'canceled')
  end

  def handle_set_push_notification(params)
    unless agent_card.capabilities.push_notifications?
      raise A2A::PushNotificationNotSupportedError
    end

    task_id = params[:taskId] || params['taskId']
    config_data = params[:pushNotificationConfig] || params['pushNotificationConfig']

    raise A2A::InvalidParamsError unless task_id && config_data

    config = A2A::Models::PushNotificationConfig.from_hash(config_data)
    @push_configs[task_id] = config

    debug_me "Push notification configured for #{task_id}"
    nil
  end

  def handle_get_push_notification(params)
    task_id = params[:taskId] || params['taskId']
    config = @push_configs[task_id]

    raise A2A::TaskNotFoundError unless config

    config
  end

  def handle_resubscribe(params)
    task_id = params[:taskId] || params['taskId']
    task = @tasks[task_id]

    raise A2A::TaskNotFoundError unless task

    # Client will reconnect to SSE stream
    nil
  end

  # Register SSE client for streaming
  def register_stream(task_id, client)
    @streaming_clients[task_id] ||= []
    @streaming_clients[task_id] << client
  end

  def unregister_stream(task_id, client)
    @streaming_clients[task_id]&.delete(client)
  end

  private

  def validate_request(request)
    raise A2A::InvalidRequestError unless request[:method]
  end

  def extract_task_params(params)
    task_id = params[:taskId] || params['taskId']
    message_data = params[:message] || params['message']
    session_id = params[:sessionId] || params['sessionId']

    raise A2A::InvalidParamsError.new(
      data: { missing: ['taskId', 'message'] }
    ) unless task_id && message_data

    message = A2A::Models::Message.from_hash(message_data)

    [task_id, message, session_id]
  end

  def create_task(task_id, message, session_id, streaming:)
    # Store session
    if session_id
      @sessions[session_id] ||= []
      @sessions[session_id] << task_id
    end

    A2A::Models::Task.new(
      id: task_id,
      session_id: session_id,
      status: {
        state: 'submitted',
        message: message,
        timestamp: Time.now.utc.iso8601
      },
      metadata: {
        streaming: streaming,
        created_at: Time.now.utc.iso8601
      }
    )
  end

  def update_task_state(task_id, new_state, message: nil, artifacts: nil)
    task = @tasks[task_id]
    return nil unless task

    updated_task = A2A::Models::Task.new(
      id: task.id,
      session_id: task.session_id,
      status: {
        state: new_state,
        message: message,
        timestamp: Time.now.utc.iso8601
      },
      artifacts: artifacts || task.artifacts,
      metadata: task.metadata
    )

    @tasks[task_id] = updated_task

    # Notify streaming clients
    notify_streaming_clients(task_id, updated_task)

    # Send push notification if configured
    send_push_notification(task_id, updated_task)

    updated_task
  end

  def notify_streaming_clients(task_id, task)
    clients = @streaming_clients[task_id] || []

    clients.each do |client|
      begin
        client.send_event('taskStatus', task: task.to_h)
      rescue => e
        debug_me "Failed to notify client: #{e.message}"
        unregister_stream(task_id, client)
      end
    end
  end

  def send_push_notification(task_id, task)
    config = @push_configs[task_id]
    return unless config && task.state.terminal?

    # Send webhook notification
    Thread.new do
      begin
        require 'net/http'
        uri = URI.parse(config.url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'

        request = Net::HTTP::Post.new(uri.request_uri)
        request['Content-Type'] = 'application/json'
        request['Authorization'] = "Bearer #{config.token}" if config.token
        request.body = { taskId: task_id, task: task.to_h }.to_json

        response = http.request(request)
        debug_me "Push notification sent: #{response.code}"

      rescue => e
        debug_me "Push notification failed: #{e.message}"
      end
    end
  end

  def start_background_workers
    # Start worker threads to process tasks
    @workers = Array.new(4) do
      Thread.new { worker_loop }
    end
  end

  def worker_loop
    loop do
      task_id = @task_queue.pop
      process_task(task_id)
    end
  rescue => e
    debug_me "Worker error: #{e.message}"
    retry
  end

  def process_task(task_id)
    task = @tasks[task_id]
    return unless task

    debug_me "Processing task: #{task_id}"

    # Update to working state
    update_task_state(task_id, 'working',
      message: A2A::Models::Message.text(
        role: 'agent',
        text: 'Processing your request...'
      )
    )

    begin
      # Process with the configured processor
      result = @processor.process(task)

      # Update to completed with results
      artifacts = [
        A2A::Models::Artifact.new(
          name: 'Response',
          parts: result.is_a?(Array) ? result : [result]
        )
      ]

      update_task_state(task_id, 'completed', artifacts: artifacts)

    rescue StandardError => e
      debug_me "Task processing failed: #{e.message}"

      update_task_state(task_id, 'failed',
        message: A2A::Models::Message.text(
          role: 'agent',
          text: "Processing failed: #{e.message}"
        )
      )
    end
  end
end

# Sinatra application
class ProductionA2AApp < Sinatra::Base
  set :server, :puma
  set :bind, '0.0.0.0'
  set :port, 4567

  def initialize(app = nil, processor: nil)
    super(app)

    @processor = processor || DefaultProcessor.new

    agent_card = create_agent_card
    @server = ProductionA2AServer.new(agent_card, processor: @processor)
  end

  # AgentCard endpoint
  get '/.well-known/agent.json' do
    content_type :json
    cache_control :public, max_age: 3600
    @server.agent_card.to_json
  end

  # JSON-RPC endpoint
  post '/a2a' do
    content_type :json

    begin
      request_data = parse_request_body

      response = @server.handle_request(request_data)

      build_json_rpc_response(request_data[:id], response).to_json

    rescue A2A::JSONRPCError => e
      build_error_response(request_data&.dig(:id), e).to_json

    rescue JSON::ParserError => e
      build_parse_error_response.to_json
    end
  end

  # SSE streaming endpoint
  get '/a2a/stream/:task_id', provides: 'text/event-stream' do
    task_id = params[:task_id]
    task = @server.tasks[task_id]

    halt 404, { error: 'Task not found' }.to_json unless task

    stream :keep_open do |out|
      client = SSEClient.new(out)
      @server.register_stream(task_id, client)

      # Send initial status
      client.send_event('taskStatus', task: task.to_h)

      # Keep connection alive
      out.callback do
        @server.unregister_stream(task_id, client)
      end
    end
  end

  # Health check
  get '/health' do
    content_type :json
    { status: 'ok', timestamp: Time.now.utc.iso8601 }.to_json
  end

  private

  def create_agent_card
    A2A::Models::AgentCard.new(
      name: ENV['AGENT_NAME'] || 'Production A2A Agent',
      url: ENV['AGENT_URL'] || 'http://localhost:4567',
      version: '1.0.0',
      description: 'A production-ready A2A agent',
      capabilities: {
        streaming: true,
        push_notifications: true,
        state_transition_history: false
      },
      skills: @processor.skills,
      provider: {
        organization: ENV['PROVIDER_ORG'] || 'Example Corp',
        url: ENV['PROVIDER_URL'] || 'https://example.com'
      }
    )
  end

  def parse_request_body
    JSON.parse(request.body.read, symbolize_names: true)
  rescue JSON::ParserError => e
    raise A2A::JSONParseError.new(data: { reason: e.message })
  end

  def build_json_rpc_response(request_id, response)
    {
      jsonrpc: '2.0',
      id: request_id,
      **response
    }
  end

  def build_error_response(request_id, error)
    {
      jsonrpc: '2.0',
      id: request_id,
      error: {
        code: error.code,
        message: error.message,
        data: error.data
      }
    }
  end

  def build_parse_error_response
    {
      jsonrpc: '2.0',
      id: nil,
      error: {
        code: -32700,
        message: 'Invalid JSON'
      }
    }
  end
end

# SSE client wrapper
class SSEClient
  def initialize(stream)
    @stream = stream
  end

  def send_event(type, data)
    @stream << "event: #{type}\n"
    @stream << "data: #{data.to_json}\n"
    @stream << "\n"
  end
end

# Default processor
class DefaultProcessor
  def skills
    [
      {
        id: 'echo',
        name: 'Echo',
        description: 'Echoes your message'
      }
    ]
  end

  def process(task)
    # Extract user message
    text = task.status.message.parts.first.text

    # Return response part
    A2A::Models::TextPart.new(text: "Echo: #{text}")
  end
end

# Run server
if __FILE__ == $0
  ProductionA2AApp.run!
end
```

## Task Storage and Management

### Example 3: Redis-Backed Task Store

```ruby
require 'redis'
require 'json'

class RedisTaskStore
  def initialize(redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379')
    @redis = Redis.new(url: redis_url)
  end

  def save(task)
    @redis.set("task:#{task.id}", task.to_json)
    @redis.expire("task:#{task.id}", 86400) # 24 hour TTL
    task
  end

  def find(task_id)
    data = @redis.get("task:#{task_id}")
    return nil unless data

    A2A::Models::Task.from_hash(JSON.parse(data, symbolize_names: true))
  end

  def delete(task_id)
    @redis.del("task:#{task_id}")
  end

  def find_by_session(session_id)
    keys = @redis.keys("task:*")
    tasks = keys.map { |k| @redis.get(k) }
                .compact
                .map { |d| JSON.parse(d, symbolize_names: true) }
                .select { |t| t[:sessionId] == session_id }
                .map { |t| A2A::Models::Task.from_hash(t) }

    tasks
  end
end
```

## Streaming with SSE

### Example 4: Advanced SSE Streaming

```ruby
require 'sinatra/base'
require 'sinatra/streaming'

class StreamingA2AServer < ProductionA2AServer
  def process_task_with_streaming(task_id)
    task = @tasks[task_id]
    return unless task

    # Update to working
    update_task_state(task_id, 'working')

    begin
      # Process in chunks with streaming
      @processor.process_streaming(task) do |chunk|
        # Create artifact chunk
        artifact = A2A::Models::Artifact.new(
          name: 'Response',
          index: 0,
          append: true,
          last_chunk: false,
          parts: [chunk]
        )

        # Notify clients
        clients = @streaming_clients[task_id] || []
        clients.each do |client|
          client.send_event('artifactUpdate', artifact: artifact.to_h)
        end

        # Small delay to simulate streaming
        sleep 0.1
      end

      # Send final task complete event
      final_task = update_task_state(task_id, 'completed')
      clients = @streaming_clients[task_id] || []
      clients.each do |client|
        client.send_event('taskComplete', task: final_task.to_h)
      end

    rescue StandardError => e
      debug_me "Streaming task failed: #{e.message}"
      update_task_state(task_id, 'failed')
    end
  end
end

# Streaming processor
class StreamingProcessor
  def process_streaming(task)
    text = task.status.message.parts.first.text
    words = text.split(' ')

    words.each do |word|
      yield A2A::Models::TextPart.new(text: "#{word} ")
    end
  end
end
```

## Background Job Processing

### Example 5: Sidekiq Integration

```ruby
require 'sidekiq'

class TaskProcessorJob
  include Sidekiq::Job

  def perform(task_id, server_class_name)
    # Reconstruct server instance
    # In production, you'd use a singleton or DI container
    server = Object.const_get(server_class_name).instance

    task = server.tasks[task_id]
    return unless task

    # Process the task
    server.send(:process_task, task_id)
  end
end

class SidekiqA2AServer < ProductionA2AServer
  def handle_send_task(params)
    task = super

    # Queue for background processing via Sidekiq
    TaskProcessorJob.perform_async(task.id, self.class.name)

    task
  end
end
```

## Authentication and Authorization

### Example 6: Bearer Token Authentication

```ruby
class AuthenticatedA2AApp < ProductionA2AApp
  before '/a2a' do
    authenticate!
  end

  def authenticate!
    auth_header = request.env['HTTP_AUTHORIZATION']

    unless auth_header && auth_header.start_with?('Bearer ')
      halt 401, { error: 'Unauthorized' }.to_json
    end

    token = auth_header.sub('Bearer ', '')

    unless valid_token?(token)
      halt 403, { error: 'Invalid token' }.to_json
    end

    @current_user = user_from_token(token)
  end

  def valid_token?(token)
    # Implement token validation
    # Check against database, JWT verification, etc.
    ENV['VALID_API_KEYS']&.split(',')&.include?(token)
  end

  def user_from_token(token)
    # Load user from token
    { id: 'user-123', api_key: token }
  end
end
```

## Complete Working Examples

### Example 7: Translation Agent Server

```ruby
#!/usr/bin/env ruby
require 'sinatra/base'
require 'a2a'
require 'json'
require 'debug_me'

class TranslationProcessor
  LANGUAGES = {
    'es' => 'Spanish',
    'fr' => 'French',
    'de' => 'German',
    'it' => 'Italian'
  }

  def skills
    [
      {
        id: 'translate',
        name: 'Translation',
        description: 'Translate text between languages',
        tags: ['translation', 'i18n'],
        examples: [
          "Translate 'Hello' to Spanish",
          "Convert 'Good morning' to French"
        ]
      }
    ]
  end

  def process(task)
    text = task.status.message.parts.first.text
    target_lang = extract_target_language(text)

    translation = translate(text, target_lang)

    [
      A2A::Models::TextPart.new(text: translation),
      A2A::Models::DataPart.new(
        data: {
          source_language: 'en',
          target_language: target_lang,
          confidence: 0.95
        }
      )
    ]
  end

  private

  def extract_target_language(text)
    LANGUAGES.each do |code, name|
      return code if text.downcase.include?(name.downcase)
    end

    'es' # Default to Spanish
  end

  def translate(text, target_lang)
    # Simple mock translation
    translations = {
      'es' => { 'hello' => 'hola', 'goodbye' => 'adiós', 'thank you' => 'gracias' },
      'fr' => { 'hello' => 'bonjour', 'goodbye' => 'au revoir', 'thank you' => 'merci' },
      'de' => { 'hello' => 'hallo', 'goodbye' => 'auf wiedersehen', 'thank you' => 'danke' }
    }

    # Extract words to translate
    words = text.downcase.scan(/\w+/)
    translated = words.map { |w| translations.dig(target_lang, w) || w }

    translated.join(' ').capitalize
  end
end

# Run the server
if __FILE__ == $0
  processor = TranslationProcessor.new
  app = ProductionA2AApp.new(processor: processor)
  app.run!
end
```

### Example 8: Multi-Agent Server

```ruby
class MultiAgentServer
  def initialize
    @agents = {}
    register_agents
  end

  def register_agent(path, agent_card, processor)
    @agents[path] = {
      card: agent_card,
      server: ProductionA2AServer.new(agent_card, processor: processor)
    }
  end

  def register_agents
    # Register translation agent
    register_agent(
      '/translate',
      create_agent_card('Translation Agent', ['translate']),
      TranslationProcessor.new
    )

    # Register echo agent
    register_agent(
      '/echo',
      create_agent_card('Echo Agent', ['echo']),
      EchoProcessor.new
    )
  end

  def create_agent_card(name, skills)
    A2A::Models::AgentCard.new(
      name: name,
      url: "http://localhost:4567",
      version: '1.0.0',
      capabilities: { streaming: true },
      skills: skills.map { |id|
        { id: id, name: id.capitalize, description: "#{id.capitalize} service" }
      }
    )
  end

  def app
    agents = @agents

    Sinatra.new do
      # Serve agent cards
      agents.each do |path, agent|
        get "#{path}/.well-known/agent.json" do
          content_type :json
          agent[:card].to_json
        end

        post "#{path}/a2a" do
          content_type :json
          # Handle request with appropriate server
          # Implementation similar to ProductionA2AApp
        end
      end
    end
  end
end
```

## Testing Servers

### Example 9: RSpec Tests

```ruby
require 'rack/test'
require 'rspec'
require_relative '../production_a2a_app'

RSpec.describe ProductionA2AApp do
  include Rack::Test::Methods

  def app
    ProductionA2AApp.new(processor: TestProcessor.new)
  end

  describe 'GET /.well-known/agent.json' do
    it 'returns agent card' do
      get '/.well-known/agent.json'

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('application/json')

      data = JSON.parse(last_response.body, symbolize_names: true)
      expect(data[:name]).to be_a(String)
      expect(data[:version]).to be_a(String)
      expect(data[:capabilities]).to be_a(Hash)
    end
  end

  describe 'POST /a2a' do
    it 'handles tasks/send' do
      request = {
        jsonrpc: '2.0',
        id: '1',
        method: 'tasks/send',
        params: {
          taskId: 'task-123',
          message: {
            role: 'user',
            parts: [{ type: 'text', text: 'Hello' }]
          }
        }
      }

      post '/a2a', request.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body, symbolize_names: true)
      expect(data[:result][:id]).to eq('task-123')
    end

    it 'returns error for invalid method' do
      request = {
        jsonrpc: '2.0',
        id: '1',
        method: 'invalid/method',
        params: {}
      }

      post '/a2a', request.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body, symbolize_names: true)
      expect(data[:error][:code]).to eq(-32601)
    end
  end
end

class TestProcessor
  def skills
    [{ id: 'test', name: 'Test', description: 'Test skill' }]
  end

  def process(task)
    A2A::Models::TextPart.new(text: 'Test response')
  end
end
```

## Production Deployment

### Example 10: Docker Configuration

```dockerfile
FROM ruby:3.2-alpine

RUN apk add --no-cache build-base postgresql-dev

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

EXPOSE 4567

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

### Example 11: Puma Configuration

```ruby
# config/puma.rb
workers Integer(ENV.fetch('WEB_CONCURRENCY', 2))
threads_count = Integer(ENV.fetch('RAILS_MAX_THREADS', 5))
threads threads_count, threads_count

preload_app!

port ENV.fetch('PORT', 4567)
environment ENV.fetch('RACK_ENV', 'production')

on_worker_boot do
  # Setup connections per worker
end
```

## Best Practices

### 1. Always Validate Input

```ruby
def handle_send_task(params)
  validate_params!(params, required: [:taskId, :message])

  # Process task
end

def validate_params!(params, required:)
  missing = required.reject { |k| params[k] || params[k.to_s] }

  unless missing.empty?
    raise A2A::InvalidParamsError.new(
      data: { missing: missing.map(&:to_s) }
    )
  end
end
```

### 2. Use Background Jobs

```ruby
# Don't process tasks synchronously in request handler
# BAD:
def handle_send_task(params)
  task = create_task(params)
  process_task(task) # Blocks request!
  task
end

# GOOD:
def handle_send_task(params)
  task = create_task(params)
  enqueue_for_processing(task)
  task
end
```

### 3. Implement Proper Timeouts

```ruby
def process_task(task_id)
  Timeout.timeout(300) do # 5 minute timeout
    # Process task
  end
rescue Timeout::Error
  update_task_state(task_id, 'failed',
    message: A2A::Models::Message.text(
      role: 'agent',
      text: 'Task timeout'
    )
  )
end
```

### 4. Log Everything

```ruby
require 'debug_me'

def handle_send_task(params)
  debug_me { [:task_id, :session_id] }
  task = create_task(params)
  debug_me "Task created: #{task.id}"
  task
rescue => e
  debug_me "Error creating task: #{e.class} - #{e.message}"
  raise
end
```

### 5. Handle Graceful Shutdown

```ruby
trap('SIGTERM') do
  puts 'Shutting down gracefully...'
  @workers.each(&:kill)
  exit
end
```

### 6. Monitor Health

```ruby
get '/health' do
  content_type :json

  {
    status: 'ok',
    tasks: {
      active: @server.tasks.count { |_, t| !t.state.terminal? },
      total: @server.tasks.size
    },
    workers: @server.workers.count(&:alive?),
    timestamp: Time.now.utc.iso8601
  }.to_json
end
```

## Summary

This guide covered:

1. **Simple Servers** - Basic Sinatra implementation
2. **Production Servers** - Full-featured with background processing
3. **Task Management** - Storage and lifecycle
4. **Streaming** - SSE implementation
5. **Background Jobs** - Sidekiq integration
6. **Authentication** - Bearer token support
7. **Testing** - RSpec examples
8. **Deployment** - Docker and production config

### Next Steps

- **[Client Examples](client.md)** - Build A2A clients
- **[Basic Examples](basic.md)** - Review data models
- **[Examples Index](index.md)** - Return to overview

---

[Back to Examples Index](index.md) | [Back to Documentation Home](../index.md)
