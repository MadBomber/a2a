# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "a2a"
require "minitest/autorun"
require "minitest/reporters"

# Use spec-style reporter for better output
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Helper module for common test utilities
module TestHelpers
  # Create a valid timestamp
  def valid_timestamp
    Time.now.utc.iso8601
  end

  # Create a simple text message
  def simple_text_message(role: "user", text: "Hello")
    A2A::Models::Message.text(role: role, text: text)
  end

  # Create a simple agent card
  def simple_agent_card
    A2A::Models::AgentCard.new(
      name: "Test Agent",
      url: "https://test.example.com/a2a",
      version: "1.0.0",
      capabilities: {
        streaming: false,
        push_notifications: false
      },
      skills: []
    )
  end

  # Create a simple task
  def simple_task(id: "task-123", state: "submitted")
    A2A::Models::Task.new(
      id: id,
      status: { state: state }
    )
  end
end

module Minitest
  class Test
    include TestHelpers
  end
end
