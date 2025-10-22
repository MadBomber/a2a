#!/usr/bin/env ruby
# Example 11: Complete CLI Client
# A command-line interface for interacting with A2A agents.
# This provides a user-friendly way to discover agents, send tasks,
# monitor status, and cancel tasks from the terminal.
#
# Usage:
#   ./cli_client.rb discover --url https://api.example.com
#   ./cli_client.rb send --url https://api.example.com --text "Hello, world!"
#   ./cli_client.rb get --url https://api.example.com --task-id task-123
#   ./cli_client.rb wait --url https://api.example.com --task-id task-123
#   ./cli_client.rb cancel --url https://api.example.com --task-id task-123

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)
require 'a2a'
require 'securerandom'
require 'optparse'
require 'logger'
require_relative 'production_client'

class A2ACLI
  attr_reader :logger

  def initialize(agent_url, logger: nil)
    @client = ProductionA2AClient.new(agent_url)
    @agent = nil
    @logger = logger || Logger.new($stdout, level: Logger::INFO)
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
      logger.info "Unknown command: #{command}"
      exit 1
    end
  end

  private

  def discover
    @agent = @client.discover

    logger.info "Agent: #{@agent.name}"
    logger.info "Version: #{@agent.version}"
    logger.info "URL: #{@agent.url}"
    logger.info "\nCapabilities:"
    logger.info "  Streaming: #{@agent.capabilities.streaming?}"
    logger.info "  Push Notifications: #{@agent.capabilities.push_notifications?}"
    logger.info "\nSkills:"
    @agent.skills.each do |skill|
      logger.info "  - #{skill.name}: #{skill.description}"
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

    logger.info "Task ID: #{task.id}"
    logger.info "State: #{task.state}"
    logger.info "Session: #{task.session_id}" if task.session_id
  end

  def get_task(task_id)
    task = @client.get_task(task_id: task_id)

    logger.info "Task ID: #{task.id}"
    logger.info "State: #{task.state}"

    if task.artifacts
      logger.info "\nArtifacts:"
      task.artifacts.each do |artifact|
        logger.info "  #{artifact.name}:"
        artifact.parts.each do |part|
          case part
          when A2A::Models::TextPart
            logger.info "    #{part.text}"
          when A2A::Models::DataPart
            logger.info "    Data: #{part.data.inspect}"
          end
        end
      end
    end
  end

  def wait_for_task(task_id)
    logger.info "Waiting for task #{task_id}..."

    task = @client.wait_for_task(task_id: task_id, max_wait: 300)

    logger.info "Task completed: #{task.state}"
    get_task(task_id)
  end

  def cancel_task(task_id)
    task = @client.cancel_task(task_id: task_id)
    logger.info "Task #{task_id} canceled: #{task.state}"
  end
end

# Parse command line arguments
if __FILE__ == $PROGRAM_NAME
  # Create logger for main block
  logger = Logger.new($stdout)
  logger.level = Logger::INFO
  logger.formatter = proc do |severity, datetime, progname, msg|
    "#{msg}\n"
  end

  options = {}
  command = ARGV.shift

  OptionParser.new do |opts|
    opts.banner = "Usage: #{$PROGRAM_NAME} COMMAND [options]"
    opts.separator ""
    opts.separator "Commands:"
    opts.separator "  discover              Discover agent capabilities"
    opts.separator "  send                  Send a task to the agent"
    opts.separator "  get                   Get task status"
    opts.separator "  wait                  Wait for task to complete"
    opts.separator "  cancel                Cancel a task"
    opts.separator ""
    opts.separator "Options:"

    opts.on("--url URL", "Agent URL (or set A2A_AGENT_URL env var)") { |v| options[:url] = v }
    opts.on("--text TEXT", "Message text for send command") { |v| options[:text] = v }
    opts.on("--task-id ID", "Task ID for get/wait/cancel commands") { |v| options[:task_id] = v }
    opts.on("--session ID", "Session ID for send command") { |v| options[:session] = v }
    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end.parse!

  # Validate command
  unless command
    logger.info "Error: Command is required"
    logger.info "Run with --help for usage information"
    exit 1
  end

  # Get agent URL
  agent_url = options[:url] || ENV['A2A_AGENT_URL']
  unless agent_url
    logger.info "Error: Agent URL is required (use --url or set A2A_AGENT_URL)"
    exit 1
  end

  # Validate command-specific options
  case command
  when 'send'
    unless options[:text]
      logger.info "Error: --text is required for send command"
      exit 1
    end
  when 'get', 'wait', 'cancel'
    unless options[:task_id]
      logger.info "Error: --task-id is required for #{command} command"
      exit 1
    end
  end

  # Run CLI
  begin
    cli = A2ACLI.new(agent_url, logger: logger)
    cli.run(command, **options)

  rescue A2A::TaskNotFoundError
    logger.info "Error: Task not found"
    exit 1
  rescue A2A::InternalError => e
    logger.info "Error: #{e.message}"
    logger.info "Data: #{e.data}" if e.data
    exit 1
  rescue A2A::JSONRPCError => e
    logger.info "Protocol error #{e.code}: #{e.message}"
    exit 1
  rescue StandardError => e
    logger.info "Unexpected error: #{e.class} - #{e.message}"
    exit 1
  end
end
