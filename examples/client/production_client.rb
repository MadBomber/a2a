#!/usr/bin/env ruby
# Example 3: Production Client Implementation
# A production-ready A2A client with connection pooling, retries, and comprehensive error handling

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)
require 'a2a'
require 'faraday'
require 'faraday/retry'
require 'json'
require 'securerandom'
require 'logger'

class ProductionA2AClient < A2A::Client::Base
  attr_reader :conn, :logger

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
    headers: {},
    logger: nil
  )
    super(agent_url)

    @timeout = timeout
    @open_timeout = open_timeout
    @max_retries = max_retries
    @retry_interval = retry_interval
    @custom_headers = headers
    @logger = logger || Logger.new($stdout, level: Logger::INFO)
    @conn = build_connection
  end

  def discover
    logger.info "Discovering agent at #{agent_url}"

    response = with_error_handling do
      @conn.get('/.well-known/agent.json')
    end

    agent_data = JSON.parse(response.body, symbolize_names: true)
    @agent_card = A2A::Models::AgentCard.from_hash(agent_data)

    logger.info "Discovered: #{@agent_card.name} v#{@agent_card.version}"
    logger.info "Skills: #{@agent_card.skills.map(&:name).join(', ')}"

    @agent_card
  end

  def send_task(task_id:, message:, session_id: nil)
    logger.debug { "task_id=#{task_id}, session_id=#{session_id}" }

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
    raise NotImplementedError, "Streaming not implemented in this example"
  end

  def get_task(task_id:)
    logger.info "Getting task: #{task_id}"

    request = build_request("tasks/get", taskId: task_id)
    response = execute_request(request)
    A2A::Models::Task.from_hash(response.result)
  end

  def cancel_task(task_id:)
    logger.info "Canceling task: #{task_id}"

    request = build_request("tasks/cancel", taskId: task_id)
    response = execute_request(request)
    A2A::Models::Task.from_hash(response.result)
  end

  def set_push_notification(task_id:, config:)
    logger.info "Setting push notification for task: #{task_id}"

    request = build_request(
      "tasks/pushNotification/set",
      taskId: task_id,
      pushNotificationConfig: config.to_h
    )

    execute_request(request)
    nil
  end

  def get_push_notification(task_id:)
    logger.info "Getting push notification config for task: #{task_id}"

    request = build_request("tasks/pushNotification/get", taskId: task_id)
    response = execute_request(request)
    A2A::Models::PushNotificationConfig.from_hash(response.result)
  end

  # Helper method for polling with exponential backoff
  def wait_for_task(task_id:, max_wait: 60, initial_interval: 1, max_interval: 10)
    logger.info "Waiting for task #{task_id} to complete"

    start_time = Time.now
    interval = initial_interval
    task = nil

    loop do
      task = get_task(task_id: task_id)

      if task.state.terminal?
        logger.info "Task completed in state: #{task.state}"
        return task
      end

      elapsed = Time.now - start_time
      if elapsed >= max_wait
        logger.info "Task timeout after #{elapsed}s"
        raise A2A::InternalError.new(
          data: { reason: "Task timeout", elapsed: elapsed }
        )
      end

      logger.info "Task state: #{task.state}, waiting #{interval}s"
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
                  logger.info "Retry #{retries}/#{opts[:max]}: #{exc&.class}"
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
    logger.info "Executing: #{request.method}"

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
    logger.info "Timeout error: #{e.message}"
    raise A2A::InternalError.new(data: { reason: "Request timeout" })
  rescue Faraday::ConnectionFailed => e
    logger.info "Connection failed: #{e.message}"
    raise A2A::InternalError.new(data: { reason: "Connection failed" })
  rescue Faraday::Error => e
    logger.info "Network error: #{e.message}"
    raise A2A::InternalError.new(data: { reason: e.message })
  end

  def parse_response(http_response)
    unless http_response.success?
      raise A2A::InternalError.new(
        data: { status: http_response.status, body: http_response.body }
      )
    end

    begin
      # Faraday's json middleware already parses the response
      data = http_response.body.is_a?(Hash) ? http_response.body : JSON.parse(http_response.body, symbolize_names: true)
      data = data.transform_keys(&:to_sym) unless data.keys.first.is_a?(Symbol)
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

    logger.info "JSON-RPC error #{code}: #{message}"

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

# Example usage
if __FILE__ == $PROGRAM_NAME
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
      logger.info "Success!"
      completed_task.artifacts.each do |artifact|
        logger.info "Artifact: #{artifact.name}"
        artifact.parts.each do |part|
          case part
          when A2A::Models::TextPart
            logger.info "  Text: #{part.text}"
          when A2A::Models::DataPart
            logger.info "  Data: #{part.data.inspect}"
          end
        end
      end
    else
      logger.info "Task failed: #{completed_task.state}"
    end

  rescue A2A::TaskNotFoundError
    logger.info "Task not found"
  rescue A2A::InternalError => e
    logger.info "Internal error: #{e.message}"
    logger.info "Data: #{e.data}"
  rescue A2A::JSONRPCError => e
    logger.info "Protocol error #{e.code}: #{e.message}"
  end
end
