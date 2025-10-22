#!/usr/bin/env ruby
# Example 8: Multi-Agent Server
# A server that hosts multiple A2A agents at different endpoints.
# Each agent has its own AgentCard, capabilities, and skills.
#
# Demonstrates how to:
# - Host multiple specialized agents in one server
# - Route requests to appropriate agent based on path
# - Share common infrastructure (server code) across agents
#
# Endpoints:
#   /translate/.well-known/agent.json - Translation agent card
#   /translate/a2a - Translation agent endpoint
#   /echo/.well-known/agent.json - Echo agent card
#   /echo/a2a - Echo agent endpoint
#
# Usage:
#   ruby multi_agent_server.rb
#   # Server starts on port 4567

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)

require 'sinatra/base'
require 'a2a'
require 'json'
require 'concurrent'
require 'logger'

require_relative 'production_server'

# Translation processor
class TranslationProcessor
  LANGUAGES = {
    'es' => 'Spanish',
    'fr' => 'French',
    'de' => 'German'
  }

  def skills
    [
      {
        id: 'translate',
        name: 'Translation',
        description: 'Translate text between languages',
        tags: ['translation', 'i18n']
      }
    ]
  end

  def process(task)
    text = task.status.message.parts.first.text
    target_lang = extract_target_language(text)
    translation = translate(text, target_lang)

    A2A::Models::TextPart.new(text: translation)
  end

  private

  def extract_target_language(text)
    LANGUAGES.each { |code, name| return code if text.downcase.include?(name.downcase) }
    'es'
  end

  def translate(text, target_lang)
    translations = {
      'es' => { 'hello' => 'hola', 'goodbye' => 'adiós' },
      'fr' => { 'hello' => 'bonjour', 'goodbye' => 'au revoir' },
      'de' => { 'hello' => 'hallo', 'goodbye' => 'auf wiedersehen' }
    }

    words = text.downcase.scan(/\w+/)
    words.map { |w| translations.dig(target_lang, w) || w }.join(' ').capitalize
  end
end

# Echo processor
class EchoProcessor
  def skills
    [
      {
        id: 'echo',
        name: 'Echo',
        description: 'Echoes your message back'
      }
    ]
  end

  def process(task)
    text = task.status.message.parts.first.text
    A2A::Models::TextPart.new(text: "Echo: #{text}")
  end
end

# Multi-agent server manager
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
      create_agent_card('Translation Agent', TranslationProcessor.new.skills),
      TranslationProcessor.new
    )

    # Register echo agent
    register_agent(
      '/echo',
      create_agent_card('Echo Agent', EchoProcessor.new.skills),
      EchoProcessor.new
    )
  end

  def create_agent_card(name, skills)
    A2A::Models::AgentCard.new(
      name: name,
      url: "http://localhost:4567",
      version: '1.0.0',
      capabilities: { streaming: true, push_notifications: true },
      skills: skills
    )
  end

  def app
    agents = @agents

    Sinatra.new do
      set :server, :puma
      set :bind, '0.0.0.0'
      set :port, 4567

      # Serve agent cards
      agents.each do |path, agent|
        get "#{path}/.well-known/agent.json" do
          content_type :json
          agent[:card].to_json
        end

        post "#{path}/a2a" do
          content_type :json

          begin
            request_data = JSON.parse(request.body.read, symbolize_names: true)
            response = agent[:server].handle_request(request_data)

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

      # List all agents
      get '/' do
        content_type :json

        {
          server: 'Multi-Agent A2A Server',
          agents: agents.keys.map do |path|
            agent = agents[path]
            {
              path: path,
              name: agent[:card].name,
              skills: agent[:card].skills.map { |s| s[:name] },
              agent_card_url: "#{path}/.well-known/agent.json",
              endpoint_url: "#{path}/a2a"
            }
          end
        }.to_json
      end

      # Health check
      get '/health' do
        content_type :json
        {
          status: 'ok',
          agents: agents.size,
          timestamp: Time.now.utc.iso8601
        }.to_json
      end
    end
  end
end

# Run server
if __FILE__ == $PROGRAM_NAME
  logger = Logger.new($stdout)
  logger.level = Logger::INFO
  logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.strftime('%H:%M:%S')}] #{severity}: #{msg}\n"
  end

  logger.info "Starting Multi-Agent Server..."

  server = MultiAgentServer.new
  app = server.app

  logger.info "Registered agents:"
  logger.info "  - Translation Agent at /translate"
  logger.info "  - Echo Agent at /echo"
  logger.info ""
  logger.info "Server endpoints:"
  logger.info "  GET  /                          - List all agents"
  logger.info "  GET  /health                    - Health check"
  logger.info "  GET  /translate/.well-known/agent.json"
  logger.info "  POST /translate/a2a"
  logger.info "  GET  /echo/.well-known/agent.json"
  logger.info "  POST /echo/a2a"

  app.run!
end
