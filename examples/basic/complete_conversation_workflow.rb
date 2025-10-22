#!/usr/bin/env ruby
# Example: Complete Conversation Workflow
# Demonstrates multi-turn conversations with session management
# Shows how to handle input-required states and maintain context across turns

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)

require 'a2a'
require 'securerandom'
require 'logger'

# Configure logger
logger = Logger.new($stdout)
logger.level = Logger::INFO
logger.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime('%H:%M:%S')}] #{severity}: #{msg}\n"
end

# Simulate a multi-turn conversation with session management
def demonstrate_conversation(logger)
  session_id = "session-#{SecureRandom.uuid}"

  logger.info "=" * 60
  logger.info "Starting Multi-Turn Conversation"
  logger.info "Session ID: #{session_id}"
  logger.info "=" * 60

  # Turn 1: Initial request (vague, needs clarification)
  logger.info ""
  logger.info "Turn 1: User asks vague question"
  logger.info "-" * 60

  task1_id = SecureRandom.uuid
  task1 = A2A::Models::Task.new(
    id: task1_id,
    session_id: session_id,
    status: {
      state: 'input-required',
      message: A2A::Models::Message.text(
        role: 'agent',
        text: "I'd be happy to help with that. Could you provide more details about what specifically you'd like to know?"
      ),
      timestamp: Time.now.utc.iso8601
    }
  )

  logger.info "User: Tell me about machine learning"
  logger.info "Agent: #{task1.status.message.parts.first.text}"
  logger.info "Task state: #{task1.state}"

  # Turn 2: User provides clarification
  logger.info ""
  logger.info "Turn 2: User provides more details"
  logger.info "-" * 60

  task2_id = SecureRandom.uuid
  task2 = A2A::Models::Task.new(
    id: task2_id,
    session_id: session_id,
    status: {
      state: 'working',
      message: A2A::Models::Message.text(
        role: 'agent',
        text: "Processing your request about supervised learning..."
      ),
      timestamp: Time.now.utc.iso8601
    }
  )

  logger.info "User: I'm interested in supervised learning algorithms for classification"
  logger.info "Agent: #{task2.status.message.parts.first.text}"
  logger.info "Task state: #{task2.state}"

  # Turn 3: Agent provides complete response
  logger.info ""
  logger.info "Turn 3: Agent provides comprehensive answer"
  logger.info "-" * 60

  task3_id = SecureRandom.uuid
  task3 = A2A::Models::Task.new(
    id: task3_id,
    session_id: session_id,
    status: {
      state: 'completed',
      message: A2A::Models::Message.text(
        role: 'agent',
        text: "Based on your interest in supervised learning for classification, here's a comprehensive overview..."
      ),
      timestamp: Time.now.utc.iso8601
    },
    artifacts: [
      A2A::Models::Artifact.new(
        name: 'Learning Resources',
        parts: [
          A2A::Models::DataPart.new(
            data: {
              algorithms: ['Decision Trees', 'Random Forests', 'SVM', 'Neural Networks'],
              resources: ['scikit-learn documentation', 'Deep Learning textbook'],
              next_steps: 'Start with decision trees for interpretability'
            }
          )
        ]
      ),
      A2A::Models::Artifact.new(
        name: 'Conversation Summary',
        parts: [
          A2A::Models::DataPart.new(
            data: {
              session_id: session_id,
              total_turns: 3,
              topic: 'supervised learning classification',
              outcome: 'comprehensive resources provided'
            }
          )
        ]
      )
    ]
  )

  logger.info "Agent: #{task3.status.message.parts.first.text}"
  logger.info "Task state: #{task3.state}"
  logger.info "Artifacts provided: #{task3.artifacts.size}"

  # Display artifacts
  logger.info ""
  logger.info "Artifacts:"
  task3.artifacts.each_with_index do |artifact, index|
    logger.info "  #{index + 1}. #{artifact.name}"
    artifact.parts.each do |part|
      if part.is_a?(A2A::Models::DataPart)
        part.data.each do |key, value|
          logger.info "     - #{key}: #{value}"
        end
      end
    end
  end

  logger.info ""
  logger.info "=" * 60
  logger.info "Conversation Complete"
  logger.info "Total turns: 3"
  logger.info "Session: #{session_id}"
  logger.info "=" * 60
end

# Example of multi-step form workflow
def demonstrate_form_workflow(logger)
  session_id = "form-session-#{SecureRandom.uuid}"

  logger.info ""
  logger.info ""
  logger.info "=" * 60
  logger.info "Multi-Step Form Workflow Example"
  logger.info "Session ID: #{session_id}"
  logger.info "=" * 60

  # Step 1: Ask for name
  logger.info ""
  logger.info "Step 1 of 3: Name"
  logger.info "-" * 60

  task1 = A2A::Models::Task.new(
    id: SecureRandom.uuid,
    session_id: session_id,
    status: {
      state: 'input-required',
      message: A2A::Models::Message.text(
        role: 'agent',
        text: 'What is your full name?'
      ),
      timestamp: Time.now.utc.iso8601
    },
    metadata: {
      progress: '0/3',
      current_field: 'name'
    }
  )

  logger.info "Agent: #{task1.status.message.parts.first.text}"
  logger.info "Progress: #{task1.metadata[:progress]}"
  logger.info "User: John Doe"

  # Step 2: Ask for email
  logger.info ""
  logger.info "Step 2 of 3: Email"
  logger.info "-" * 60

  task2 = A2A::Models::Task.new(
    id: SecureRandom.uuid,
    session_id: session_id,
    status: {
      state: 'input-required',
      message: A2A::Models::Message.text(
        role: 'agent',
        text: 'What is your email address?'
      ),
      timestamp: Time.now.utc.iso8601
    },
    metadata: {
      progress: '1/3',
      current_field: 'email'
    }
  )

  logger.info "Agent: #{task2.status.message.parts.first.text}"
  logger.info "Progress: #{task2.metadata[:progress]}"
  logger.info "User: john.doe@example.com"

  # Step 3: Ask for preferences
  logger.info ""
  logger.info "Step 3 of 3: Preferences"
  logger.info "-" * 60

  task3 = A2A::Models::Task.new(
    id: SecureRandom.uuid,
    session_id: session_id,
    status: {
      state: 'input-required',
      message: A2A::Models::Message.text(
        role: 'agent',
        text: 'What are your notification preferences?'
      ),
      timestamp: Time.now.utc.iso8601
    },
    metadata: {
      progress: '2/3',
      current_field: 'preferences'
    }
  )

  logger.info "Agent: #{task3.status.message.parts.first.text}"
  logger.info "Progress: #{task3.metadata[:progress]}"
  logger.info "User: Email notifications only"

  # Completion
  logger.info ""
  logger.info "Form Completion"
  logger.info "-" * 60

  task4 = A2A::Models::Task.new(
    id: SecureRandom.uuid,
    session_id: session_id,
    status: {
      state: 'completed',
      message: A2A::Models::Message.text(
        role: 'agent',
        text: 'Thank you! Your registration has been completed.'
      ),
      timestamp: Time.now.utc.iso8601
    },
    artifacts: [
      A2A::Models::Artifact.new(
        name: 'Completed Registration',
        parts: [
          A2A::Models::DataPart.new(
            data: {
              name: 'John Doe',
              email: 'john.doe@example.com',
              preferences: 'Email notifications only'
            }
          )
        ]
      )
    ]
  )

  logger.info "Agent: #{task4.status.message.parts.first.text}"
  logger.info "Form data collected:"
  task4.artifacts.first.parts.first.data.each do |key, value|
    logger.info "  - #{key}: #{value}"
  end

  logger.info ""
  logger.info "=" * 60
  logger.info "Form Workflow Complete"
  logger.info "=" * 60
end

# Run demonstrations
if __FILE__ == $PROGRAM_NAME
  demonstrate_conversation(logger)
  demonstrate_form_workflow(logger)
end
