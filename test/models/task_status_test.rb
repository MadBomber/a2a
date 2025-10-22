# frozen_string_literal: true

require "test_helper"

class TaskStatusTest < Minitest::Test
  describe "initialization" do
    def test_creates_task_status_with_state_string
      status = A2A::Models::TaskStatus.new(state: "submitted")

      assert_kind_of A2A::Models::TaskState, status.state
      assert_equal "submitted", status.state.to_s
      assert_nil status.message
    end

    def test_creates_task_status_with_task_state_object
      task_state = A2A::Models::TaskState.new("working")
      status = A2A::Models::TaskStatus.new(state: task_state)

      assert_equal task_state, status.state
    end

    def test_creates_task_status_with_message
      message = A2A::Models::Message.text(role: "agent", text: "Processing your request")
      status = A2A::Models::TaskStatus.new(state: "working", message: message)

      assert_equal message, status.message
    end

    def test_creates_task_status_with_custom_timestamp
      timestamp = "2025-10-21T12:00:00Z"
      status = A2A::Models::TaskStatus.new(state: "completed", timestamp: timestamp)

      assert_equal timestamp, status.timestamp
    end

    def test_auto_generates_timestamp_when_not_provided
      status = A2A::Models::TaskStatus.new(state: "submitted")

      refute_nil status.timestamp
      assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, status.timestamp)
    end

    def test_normalizes_message_hash_to_message_object
      message_hash = {
        role: "agent",
        parts: [{ type: "text", text: "Status update" }]
      }
      status = A2A::Models::TaskStatus.new(state: "working", message: message_hash)

      assert_kind_of A2A::Models::Message, status.message
      assert_equal "agent", status.message.role
    end
  end

  describe "to_h" do
    def test_to_h_with_state_only
      status = A2A::Models::TaskStatus.new(state: "submitted")
      hash = status.to_h

      assert_equal "submitted", hash[:state]
      assert hash.key?(:timestamp)
      refute hash.key?(:message)
    end

    def test_to_h_with_state_and_message
      message = A2A::Models::Message.text(role: "agent", text: "Processing")
      status = A2A::Models::TaskStatus.new(state: "working", message: message)
      hash = status.to_h

      assert_equal "working", hash[:state]
      assert_kind_of Hash, hash[:message]
      assert_equal "agent", hash[:message][:role]
    end

    def test_to_h_with_all_fields
      message = A2A::Models::Message.text(role: "agent", text: "Done")
      timestamp = "2025-10-21T12:00:00Z"
      status = A2A::Models::TaskStatus.new(
        state: "completed",
        message: message,
        timestamp: timestamp
      )
      hash = status.to_h

      assert_equal "completed", hash[:state]
      assert_equal timestamp, hash[:timestamp]
      assert_kind_of Hash, hash[:message]
    end

    def test_to_h_excludes_nil_message
      status = A2A::Models::TaskStatus.new(state: "submitted", message: nil)
      hash = status.to_h

      refute hash.key?(:message)
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        state: "working",
        timestamp: "2025-10-21T12:00:00Z"
      }
      status = A2A::Models::TaskStatus.from_hash(hash)

      assert_equal "working", status.state.to_s
      assert_equal "2025-10-21T12:00:00Z", status.timestamp
      assert_nil status.message
    end

    def test_from_hash_with_string_keys
      hash = {
        "state" => "completed",
        "timestamp" => "2025-10-21T13:00:00Z"
      }
      status = A2A::Models::TaskStatus.from_hash(hash)

      assert_equal "completed", status.state.to_s
      assert_equal "2025-10-21T13:00:00Z", status.timestamp
    end

    def test_from_hash_with_message
      hash = {
        state: "failed",
        message: {
          role: "agent",
          parts: [{ type: "text", text: "Error occurred" }]
        },
        timestamp: "2025-10-21T14:00:00Z"
      }
      status = A2A::Models::TaskStatus.from_hash(hash)

      assert_kind_of A2A::Models::Message, status.message
      assert_equal "agent", status.message.role
      assert_equal "Error occurred", status.message.parts.first.text
    end

    def test_from_hash_without_timestamp
      hash = { state: "submitted" }
      status = A2A::Models::TaskStatus.from_hash(hash)

      refute_nil status.timestamp
    end

    def test_from_hash_handles_nil_message
      hash = {
        state: "working",
        message: nil,
        timestamp: "2025-10-21T12:00:00Z"
      }
      status = A2A::Models::TaskStatus.from_hash(hash)

      assert_nil status.message
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_state_only
      original = A2A::Models::TaskStatus.new(
        state: "submitted",
        timestamp: "2025-10-21T12:00:00Z"
      )

      hash = original.to_h
      restored = A2A::Models::TaskStatus.from_hash(hash)

      assert_equal original.state.to_s, restored.state.to_s
      assert_equal original.timestamp, restored.timestamp
      assert_nil restored.message
    end

    def test_round_trip_with_message
      original = A2A::Models::TaskStatus.new(
        state: "working",
        message: A2A::Models::Message.text(role: "agent", text: "In progress"),
        timestamp: "2025-10-21T12:00:00Z"
      )

      hash = original.to_h
      restored = A2A::Models::TaskStatus.from_hash(hash)

      assert_equal original.state.to_s, restored.state.to_s
      assert_equal original.timestamp, restored.timestamp
      assert_equal original.message.role, restored.message.role
      assert_equal original.message.parts.first.text, restored.message.parts.first.text
    end
  end

  describe "state delegations" do
    def test_accesses_state_methods
      status = A2A::Models::TaskStatus.new(state: "completed")

      assert status.state.completed?
      refute status.state.working?
    end

    def test_state_is_terminal
      completed_status = A2A::Models::TaskStatus.new(state: "completed")
      assert completed_status.state.terminal?

      working_status = A2A::Models::TaskStatus.new(state: "working")
      refute working_status.state.terminal?
    end
  end

  describe "edge cases" do
    def test_handles_all_valid_states
      A2A::Models::TaskState::STATES.each do |state_value|
        status = A2A::Models::TaskStatus.new(state: state_value)
        assert_equal state_value, status.state.to_s
      end
    end

    def test_raises_error_for_invalid_state
      error = assert_raises(ArgumentError) do
        A2A::Models::TaskStatus.new(state: "invalid-state")
      end

      assert_match(/Invalid task state/, error.message)
    end

    def test_handles_message_with_multiple_parts
      message = A2A::Models::Message.new(
        role: "agent",
        parts: [
          A2A::Models::TextPart.new(text: "Status:"),
          A2A::Models::DataPart.new(data: { "progress" => 75 })
        ]
      )
      status = A2A::Models::TaskStatus.new(state: "working", message: message)

      assert_equal 2, status.message.parts.length
    end

    def test_handles_message_with_metadata
      message = A2A::Models::Message.text(
        role: "agent",
        text: "Update",
        metadata: { "priority" => "high" }
      )
      status = A2A::Models::TaskStatus.new(state: "working", message: message)
      hash = status.to_h

      assert_equal({ "priority" => "high" }, hash[:message][:metadata])
    end
  end

  describe "use cases" do
    def test_represents_task_submission
      status = A2A::Models::TaskStatus.new(state: "submitted")

      assert status.state.submitted?
      refute status.state.terminal?
    end

    def test_represents_task_in_progress
      status = A2A::Models::TaskStatus.new(
        state: "working",
        message: A2A::Models::Message.text(
          role: "agent",
          text: "Processing your request..."
        )
      )

      assert status.state.working?
      assert_equal "Processing your request...", status.message.parts.first.text
    end

    def test_represents_task_completion
      status = A2A::Models::TaskStatus.new(
        state: "completed",
        message: A2A::Models::Message.text(
          role: "agent",
          text: "Task completed successfully"
        )
      )

      assert status.state.completed?
      assert status.state.terminal?
    end

    def test_represents_task_failure
      status = A2A::Models::TaskStatus.new(
        state: "failed",
        message: A2A::Models::Message.text(
          role: "agent",
          text: "Task failed due to invalid input"
        )
      )

      assert status.state.failed?
      assert status.state.terminal?
    end

    def test_represents_input_required_state
      status = A2A::Models::TaskStatus.new(
        state: "input-required",
        message: A2A::Models::Message.new(
          role: "agent",
          parts: [
            A2A::Models::TextPart.new(text: "Please provide additional information:"),
            A2A::Models::DataPart.new(
              data: {
                "type" => "form",
                "fields" => [{ "name" => "email", "type" => "text" }]
              }
            )
          ]
        )
      )

      assert status.state.input_required?
      refute status.state.terminal?
    end
  end
end
