#!/usr/bin/env ruby
# Example 1: Basic Faraday Client
# A simple A2A client implementation using Faraday for HTTP communication

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)
require 'a2a'
require 'faraday'
require 'json'
require 'securerandom'
require 'logger'

class SimpleA2AClient < A2A::Client::Base
  attr_reader :logger
  def initialize(agent_url, timeout: 30, logger: nil)
    super(agent_url)
    @timeout = timeout
    @logger = logger || Logger.new($stdout, level: Logger::INFO)
    @conn = build_connection
  end

  def discover
    logger.info "Discovering agent at #{agent_url}"

    response = @conn.get('/.well-known/agent.json')

    unless response.success?
      raise A2A::InternalError.new(
        data: { reason: "Failed to fetch AgentCard", status: response.status }
      )
    end

    agent_data = JSON.parse(response.body, symbolize_names: true)
    @agent_card = A2A::Models::AgentCard.from_hash(agent_data)

    logger.info "Discovered agent: #{@agent_card.name} v#{@agent_card.version}"
    @agent_card

  rescue Faraday::Error => e
    logger.error "Network error during discovery: #{e.message}"
    raise A2A::InternalError.new(data: { reason: e.message })
  end

  def send_task(task_id:, message:, session_id: nil)
    logger.info "Sending task #{task_id}"

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

    logger.info "Task submitted: #{task.id} - state: #{task.state}"
    task
  end

  def get_task(task_id:)
    logger.info "Getting task #{task_id}"

    request = build_json_rpc_request(
      method: "tasks/get",
      params: { taskId: task_id }
    )

    response = post_json_rpc(request)
    A2A::Models::Task.from_hash(response.result)
  end

  def cancel_task(task_id:)
    logger.info "Canceling task #{task_id}"

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
    logger.debug "Sending JSON-RPC request: #{request.method}"

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
    logger.error "Network error: #{e.message}"
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

# Example usage
if __FILE__ == $PROGRAM_NAME
  # Configure logger
  logger = Logger.new($stdout)
  logger.level = Logger::INFO
  logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.strftime('%H:%M:%S')}] #{severity}: #{msg}\n"
  end

  # Create client
  client = SimpleA2AClient.new('https://api.example.com', logger: logger)

  # Discover agent
  agent = client.discover
  logger.info "Connected to: #{agent.name}"
  logger.info "Capabilities: streaming=#{agent.capabilities.streaming?}"

  # Send a task
  message = A2A::Models::Message.text(
    role: "user",
    text: "Translate 'Hello' to Spanish"
  )

  task = client.send_task(
    task_id: SecureRandom.uuid,
    message: message
  )

  logger.info "Polling for task completion..."

  # Poll for completion
  until task.state.terminal?
    sleep 1
    task = client.get_task(task_id: task.id)
    logger.info "State: #{task.state}"
  end

  # Get results
  if task.state.completed?
    logger.info "Result: #{task.artifacts.first.parts.first.text}"
  else
    logger.error "Task failed: #{task.status.message&.parts&.first&.text}"
  end
end
