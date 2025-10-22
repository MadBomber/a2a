#!/usr/bin/env ruby
# frozen_string_literal: true

# Example demonstrating basic usage of the A2A gem

require_relative '../lib/a2a'

# Example 1: Creating an AgentCard
puts "=== Example 1: Creating an AgentCard ==="

agent_card = A2A::Models::AgentCard.new(
  name: "Example Agent",
  url: "https://example.com/a2a",
  version: "1.0.0",
  capabilities: {
    streaming: true,
    push_notifications: false,
    state_transition_history: true
  },
  skills: [
    {
      id: "text-processing",
      name: "Text Processing",
      description: "Process and analyze text content",
      tags: ["nlp", "text"],
      examples: ["Analyze sentiment", "Extract keywords"]
    },
    {
      id: "translation",
      name: "Translation",
      description: "Translate text between languages",
      tags: ["translation", "i18n"]
    }
  ],
  provider: {
    organization: "Example Corp",
    url: "https://example.com"
  },
  description: "An example agent for demonstration purposes"
)

puts "Agent Name: #{agent_card.name}"
puts "Agent URL: #{agent_card.url}"
puts "Skills: #{agent_card.skills.map(&:name).join(', ')}"
puts "Supports streaming: #{agent_card.capabilities.streaming?}"
puts

# Example 2: Creating Messages with different part types
puts "=== Example 2: Creating Messages ==="

# Text message
text_message = A2A::Models::Message.text(
  role: "user",
  text: "Hello, agent! Can you help me?"
)
puts "Text Message: #{text_message.parts.first.text}"

# Message with multiple parts
mixed_message = A2A::Models::Message.new(
  role: "agent",
  parts: [
    A2A::Models::TextPart.new(text: "Here are the results:"),
    A2A::Models::DataPart.new(
      data: {
        results: [
          { id: 1, value: "Result 1" },
          { id: 2, value: "Result 2" }
        ]
      }
    )
  ]
)
puts "Mixed message has #{mixed_message.parts.length} parts"
puts

# Example 3: Creating a Task
puts "=== Example 3: Creating a Task ==="

task = A2A::Models::Task.new(
  id: "task-#{Time.now.to_i}",
  session_id: "session-123",
  status: {
    state: "working"
  },
  metadata: {
    priority: "high",
    tags: ["example"]
  }
)

puts "Task ID: #{task.id}"
puts "Task State: #{task.state}"
puts "Is terminal state? #{task.state.terminal?}"
puts

# Example 4: Working with task states
puts "=== Example 4: Task States ==="

states = %w[submitted working input-required completed failed canceled]
states.each do |state_name|
  state = A2A::Models::TaskState.new(state_name)
  puts "#{state_name}: terminal=#{state.terminal?}"
end
puts

# Example 5: Creating Artifacts
puts "=== Example 5: Creating Artifacts ==="

artifact = A2A::Models::Artifact.new(
  name: "Analysis Results",
  description: "Results from text analysis",
  parts: [
    A2A::Models::TextPart.new(
      text: "Analysis completed successfully"
    ),
    A2A::Models::DataPart.new(
      data: {
        word_count: 1234,
        sentiment: "positive",
        keywords: ["example", "test", "demo"]
      }
    )
  ]
)

puts "Artifact: #{artifact.name}"
puts "Parts: #{artifact.parts.length}"
puts

# Example 6: JSON serialization
puts "=== Example 6: JSON Serialization ==="

require 'json'

agent_json = JSON.pretty_generate(agent_card.to_h)
puts "AgentCard as JSON:"
puts agent_json[0..200] + "..."
puts

# Example 7: Error handling
puts "=== Example 7: Error Handling ==="

begin
  # Try to create a task with invalid state
  invalid_state = A2A::Models::TaskState.new("invalid-state")
rescue ArgumentError => e
  puts "Caught error: #{e.message}"
end

begin
  # Try to create file content without bytes or uri
  A2A::Models::FileContent.new(name: "test.txt")
rescue ArgumentError => e
  puts "Caught error: #{e.message}"
end

puts "\nAll examples completed successfully!"
