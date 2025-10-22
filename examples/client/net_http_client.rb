#!/usr/bin/env ruby
# Example 5: Net::HTTP Client
# A pure Ruby A2A client implementation using only Net::HTTP from the standard library.
# This client has no external dependencies (no Faraday), making it ideal for
# environments where you want to minimize dependencies.

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)
require 'a2a'
require 'net/http'
require 'json'
require 'uri'
require 'securerandom'
require 'logger'

class NetHTTPClient < A2A::Client::Base
  def initialize(agent_url, timeout: 30)
    super(agent_url)
    @timeout = timeout
    @uri = URI.parse(agent_url)
  end

  def discover
    logger.info "Discovering agent at #{agent_url}"

    uri = URI.join(@uri, '/.well-known/agent.json')
    response = http_get(uri)

    agent_data = JSON.parse(response.body, symbolize_names: true)
    @agent_card = A2A::Models::AgentCard.from_hash(agent_data)

    logger.info "Discovered: #{@agent_card.name}"
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
    logger.info "HTTP GET error: #{e.message}"
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
    logger.info "HTTP POST error: #{e.message}"
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

# Example usage
if __FILE__ == $PROGRAM_NAME
  # Create client (no external dependencies required!)
  client = NetHTTPClient.new('https://api.example.com')

  begin
    # Discover agent
    agent = client.discover
    logger.info "Connected to: #{agent.name}"
    logger.info "Version: #{agent.version}"

    # Send a task
    message = A2A::Models::Message.text(
      role: "user",
      text: "Translate 'Hello, world!' to Spanish"
    )

    task = client.send_task(
      task_id: SecureRandom.uuid,
      message: message
    )

    logger.info "Task submitted: #{task.id}"
    logger.info "State: #{task.state}"

    # Poll for completion
    max_attempts = 10
    attempt = 0

    until task.state.terminal? || attempt >= max_attempts
      sleep 2
      task = client.get_task(task_id: task.id)
      logger.info "State: #{task.state}"
      attempt += 1
    end

    # Display results
    if task.state.completed?
      logger.info "Task completed successfully!"
      task.artifacts&.each do |artifact|
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
      logger.info "Task did not complete: #{task.state}"
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
