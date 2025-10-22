#!/usr/bin/env ruby
# Example 1: Basic Sinatra Server
# A simple A2A server implementation using Sinatra

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)

require 'sinatra/base'
require 'a2a'
require 'json'
require 'securerandom'
require 'logger'


class SimpleA2AServer < A2A::Server::Base
  attr_reader :tasks

  def initialize(agent_card, logger: nil)
    super(agent_card, logger: logger)
    @tasks = {}
  end

  def handle_request(request)
    logger.info "Handling request: #{request[:method]}"

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
    logger.info "Task #{task_id} completed"
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
if __FILE__ == $PROGRAM_NAME
  A2AApp.run! port: 4567
end
