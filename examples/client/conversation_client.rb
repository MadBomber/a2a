#!/usr/bin/env ruby
# Example 12: Multi-Turn Conversation Client
# Demonstrates maintaining conversation context across multiple task submissions

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)
require 'a2a'
require 'securerandom'
require 'logger'
require_relative 'production_client'

class ConversationClient
  attr_reader :session_id, :client, :history, :logger

  def initialize(agent_url, logger: nil)
    @logger = logger || Logger.new($stdout, level: Logger::INFO)
    @client = ProductionA2AClient.new(agent_url, logger: @logger)
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
      logger.info "\n--- Turn #{i + 1} ---"
      logger.info "User: #{turn[:user]}"
      logger.info "Agent: #{extract_response(turn[:task])}"
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

# Example usage
if __FILE__ == $PROGRAM_NAME
  # Create logger
  logger = Logger.new($stdout)
  logger.level = Logger::INFO
  logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.strftime('%H:%M:%S')}] #{msg}\n"
  end

  conv = ConversationClient.new('http://localhost:4567', logger: logger)

  logger.info "User: Translate 'Hello' to Spanish"
  logger.info "Agent: #{conv.send("Translate 'Hello' to Spanish")}"

  logger.info "\nUser: Now to French"
  logger.info "Agent: #{conv.send("Now to French")}"

  logger.info "\nUser: And to German"
  logger.info "Agent: #{conv.send("And to German")}"

  conv.print_history
end
