#!/usr/bin/env ruby
# Example: Error Recovery Workflow
# Demonstrates handling errors and recovery in A2A task processing

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)

require 'a2a'
require 'securerandom'
require 'logger'

# Configure logger
logger = Logger.new($stdout)
logger.level = Logger::INFO
logger.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
end

# Simulate processing a user request
def process_user_request(text, logger)
  task_id = SecureRandom.uuid
  logger.info "Processing request: #{task_id}"

  # Simulate task processing
  if text.include?('error')
    raise StandardError, 'Translation service unavailable'
  end

  # Create completed task
  task = A2A::Models::Task.new(
    id: task_id,
    status: {
      state: 'completed',
      timestamp: Time.now.utc.iso8601
    },
    artifacts: [
      A2A::Models::Artifact.new(
        name: 'Translation Result',
        parts: [
          A2A::Models::TextPart.new(text: "Translated: #{text}")
        ]
      )
    ]
  )

  logger.info "Task #{task_id} completed successfully"
  task

rescue StandardError => e
  logger.error "Task #{task_id} failed: #{e.message}"

  # Create failed task with error message
  A2A::Models::Task.new(
    id: task_id,
    status: {
      state: 'failed',
      message: A2A::Models::Message.text(
        role: 'agent',
        text: "Sorry, translation failed: #{e.message}"
      ),
      timestamp: Time.now.utc.iso8601
    }
  )
end

# Example usage
if __FILE__ == $PROGRAM_NAME
  logger.info "=" * 60
  logger.info "Testing Success Case"
  logger.info "=" * 60

  # Success case
  task1 = process_user_request("Hello", logger)
  logger.info "Task 1 state: #{task1.state}"
  logger.info "Result: #{task1.artifacts.first.parts.first.text}" if task1.artifacts.any?

  logger.info ""
  logger.info "=" * 60
  logger.info "Testing Error Case"
  logger.info "=" * 60

  # Error case
  task2 = process_user_request("Trigger error please", logger)
  logger.info "Task 2 state: #{task2.state}"
  logger.warn "Error message: #{task2.status.message.parts.first.text}" if task2.status.message
end
