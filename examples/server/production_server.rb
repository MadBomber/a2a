#!/usr/bin/env ruby
# Example 2: Production Server Implementation
# A complete production-ready A2A server with:
# - Background task processing with worker threads
# - SSE streaming support for real-time updates
# - Push notification webhook support
# - Session management
# - Comprehensive error handling
# - Thread-safe concurrent operations
#
# Usage:
#   ruby production_server.rb
#   # Server starts on port 4567
#
# Environment Variables:
#   AGENT_NAME - Agent name (default: "Production A2A Agent")
#   AGENT_URL - Public URL (default: "http://localhost:4567")
#   PROVIDER_ORG - Provider organization
#   PROVIDER_URL - Provider URL

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)

require 'sinatra/base'
require 'a2a'
require 'json'
require 'securerandom'
require 'thread'
require 'concurrent'
require 'logger'


class ProductionA2AServer < A2A::Server::Base
  attr_reader :tasks, :push_configs, :sessions

  def initialize(agent_card, processor:, logger: nil)
    super(agent_card, logger: logger)

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

    logger.info "Task #{task_id} queued"
    task
  end

  def handle_send_task_streaming(params)
    task_id, message, session_id = extract_task_params(params)

    task = create_task(task_id, message, session_id, streaming: true)
    @tasks[task_id] = task

    # Queue for background processing
    @task_queue << task_id

    logger.info "Streaming task #{task_id} queued"
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

    logger.info "Push notification configured for #{task_id}"
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
        logger.info "Failed to notify client: #{e.message}"
        unregister_stream(task_id, client)
      end
    end
  end

  def send_push_notification(task_id, task)
    config = @push_configs[task_id]
    return unless config && task.state.terminal?

    # Send webhook notification in background
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
        logger.info "Push notification sent: #{response.code}"

      rescue => e
        logger.info "Push notification failed: #{e.message}"
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
    logger.info "Worker error: #{e.message}"
    retry
  end

  def process_task(task_id)
    task = @tasks[task_id]
    return unless task

    logger.info "Processing task: #{task_id}"

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
      logger.info "Task processing failed: #{e.message}"

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
if __FILE__ == $PROGRAM_NAME
  logger = Logger.new($stdout)
  logger.level = Logger::INFO
  logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.strftime('%H:%M:%S')}] #{severity}: #{msg}\n"
  end

  logger.info "Starting Production A2A Server..."
  logger.info "Agent URL: #{ENV['AGENT_URL'] || 'http://localhost:4567'}"
  ProductionA2AApp.run!
end
