# frozen_string_literal: true

require "test_helper"

class TaskTest < Minitest::Test
  describe "initialization" do
    def test_creates_task_with_id_and_status_hash
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "submitted" }
      )

      assert_equal "task-123", task.id
      assert_kind_of A2A::Models::TaskStatus, task.status
      assert_equal "submitted", task.status.state.to_s
    end

    def test_creates_task_with_status_object
      status = A2A::Models::TaskStatus.new(state: "working")
      task = A2A::Models::Task.new(id: "task-456", status: status)

      assert_equal status, task.status
    end

    def test_creates_task_with_session_id
      task = A2A::Models::Task.new(
        id: "task-123",
        session_id: "session-abc",
        status: { state: "submitted" }
      )

      assert_equal "session-abc", task.session_id
    end

    def test_creates_task_with_artifacts
      artifacts = [
        A2A::Models::Artifact.new(
          parts: [A2A::Models::TextPart.new(text: "Result")]
        )
      ]
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "completed" },
        artifacts: artifacts
      )

      assert_equal 1, task.artifacts.length
      assert_kind_of A2A::Models::Artifact, task.artifacts.first
    end

    def test_creates_task_with_metadata
      metadata = { "priority" => "high", "user_id" => "user-123" }
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "submitted" },
        metadata: metadata
      )

      assert_equal metadata, task.metadata
    end

    def test_normalizes_artifact_hashes
      artifact_hashes = [
        { parts: [{ type: "text", text: "Output 1" }] },
        { parts: [{ type: "text", text: "Output 2" }] }
      ]
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "completed" },
        artifacts: artifact_hashes
      )

      assert_equal 2, task.artifacts.length
      assert_kind_of A2A::Models::Artifact, task.artifacts.first
    end
  end

  describe "state method" do
    def test_state_returns_task_status_state
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "working" }
      )

      assert_kind_of A2A::Models::TaskState, task.state
      assert_equal "working", task.state.to_s
    end

    def test_state_reflects_current_status
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "completed" }
      )

      assert task.state.completed?
      assert task.state.terminal?
    end
  end

  describe "to_h" do
    def test_to_h_with_minimal_fields
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "submitted" }
      )
      hash = task.to_h

      assert_equal "task-123", hash[:id]
      assert_kind_of Hash, hash[:status]
      assert_equal "submitted", hash[:status][:state]
      refute hash.key?(:sessionId)
      refute hash.key?(:artifacts)
      refute hash.key?(:metadata)
    end

    def test_to_h_with_session_id
      task = A2A::Models::Task.new(
        id: "task-123",
        session_id: "session-xyz",
        status: { state: "working" }
      )
      hash = task.to_h

      assert_equal "session-xyz", hash[:sessionId]
    end

    def test_to_h_with_artifacts
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "completed" },
        artifacts: [
          A2A::Models::Artifact.new(
            name: "result",
            parts: [A2A::Models::TextPart.new(text: "Done")]
          )
        ]
      )
      hash = task.to_h

      assert_equal 1, hash[:artifacts].length
      assert_kind_of Hash, hash[:artifacts][0]
      assert_equal "result", hash[:artifacts][0][:name]
    end

    def test_to_h_with_metadata
      metadata = { "version" => "1.0" }
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "submitted" },
        metadata: metadata
      )
      hash = task.to_h

      assert_equal metadata, hash[:metadata]
    end

    def test_to_h_uses_camel_case_for_session_id
      task = A2A::Models::Task.new(
        id: "task-123",
        session_id: "session-123",
        status: { state: "submitted" }
      )
      hash = task.to_h

      assert hash.key?(:sessionId)
      refute hash.key?(:session_id)
    end

    def test_to_h_with_all_fields
      task = A2A::Models::Task.new(
        id: "task-123",
        session_id: "session-abc",
        status: {
          state: "completed",
          message: { role: "agent", parts: [{ type: "text", text: "Done" }] }
        },
        artifacts: [
          A2A::Models::Artifact.new(
            parts: [A2A::Models::TextPart.new(text: "Result")]
          )
        ],
        metadata: { "key" => "value" }
      )
      hash = task.to_h

      assert_equal "task-123", hash[:id]
      assert_equal "session-abc", hash[:sessionId]
      assert_equal "completed", hash[:status][:state]
      assert_equal 1, hash[:artifacts].length
      assert_equal({ "key" => "value" }, hash[:metadata])
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        id: "task-123",
        status: { state: "working" }
      }
      task = A2A::Models::Task.from_hash(hash)

      assert_equal "task-123", task.id
      assert_equal "working", task.state.to_s
    end

    def test_from_hash_with_string_keys
      hash = {
        "id" => "task-456",
        "status" => { "state" => "completed" }
      }
      task = A2A::Models::Task.from_hash(hash)

      assert_equal "task-456", task.id
      assert_equal "completed", task.state.to_s
    end

    def test_from_hash_with_session_id_camel_case
      hash = {
        id: "task-123",
        sessionId: "session-xyz",
        status: { state: "submitted" }
      }
      task = A2A::Models::Task.from_hash(hash)

      assert_equal "session-xyz", task.session_id
    end

    def test_from_hash_with_session_id_snake_case
      hash = {
        id: "task-123",
        session_id: "session-abc",
        status: { state: "submitted" }
      }
      task = A2A::Models::Task.from_hash(hash)

      assert_equal "session-abc", task.session_id
    end

    def test_from_hash_with_artifacts
      hash = {
        id: "task-123",
        status: { state: "completed" },
        artifacts: [
          {
            parts: [{ type: "text", text: "Output" }]
          }
        ]
      }
      task = A2A::Models::Task.from_hash(hash)

      assert_equal 1, task.artifacts.length
      assert_kind_of A2A::Models::Artifact, task.artifacts.first
    end

    def test_from_hash_with_metadata
      hash = {
        id: "task-123",
        status: { state: "submitted" },
        metadata: { "user_id" => "user-123" }
      }
      task = A2A::Models::Task.from_hash(hash)

      assert_equal({ "user_id" => "user-123" }, task.metadata)
    end

    def test_from_hash_with_nil_artifacts
      hash = {
        id: "task-123",
        status: { state: "submitted" },
        artifacts: nil
      }
      task = A2A::Models::Task.from_hash(hash)

      assert_nil task.artifacts
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_minimal_data
      original = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "submitted", timestamp: "2025-10-21T12:00:00Z" }
      )

      hash = original.to_h
      restored = A2A::Models::Task.from_hash(hash)

      assert_equal original.id, restored.id
      assert_equal original.state.to_s, restored.state.to_s
      assert_equal original.status.timestamp, restored.status.timestamp
    end

    def test_round_trip_with_all_fields
      original = A2A::Models::Task.new(
        id: "task-456",
        session_id: "session-xyz",
        status: {
          state: "completed",
          message: { role: "agent", parts: [{ type: "text", text: "Success" }] },
          timestamp: "2025-10-21T13:00:00Z"
        },
        artifacts: [
          A2A::Models::Artifact.new(
            name: "output",
            parts: [A2A::Models::TextPart.new(text: "Result data")]
          )
        ],
        metadata: { "priority" => "high" }
      )

      hash = original.to_h
      restored = A2A::Models::Task.from_hash(hash)

      assert_equal original.id, restored.id
      assert_equal original.session_id, restored.session_id
      assert_equal original.state.to_s, restored.state.to_s
      assert_equal original.artifacts.length, restored.artifacts.length
      assert_equal original.metadata, restored.metadata
    end
  end

  describe "state management" do
    def test_task_with_submitted_state
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "submitted" }
      )

      assert task.state.submitted?
      refute task.state.terminal?
    end

    def test_task_with_working_state
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "working" }
      )

      assert task.state.working?
      refute task.state.terminal?
    end

    def test_task_with_input_required_state
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "input-required" }
      )

      assert task.state.input_required?
      refute task.state.terminal?
    end

    def test_task_with_completed_state
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "completed" }
      )

      assert task.state.completed?
      assert task.state.terminal?
    end

    def test_task_with_canceled_state
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "canceled" }
      )

      assert task.state.canceled?
      assert task.state.terminal?
    end

    def test_task_with_failed_state
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "failed" }
      )

      assert task.state.failed?
      assert task.state.terminal?
    end
  end

  describe "edge cases" do
    def test_handles_empty_artifacts_array
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "submitted" },
        artifacts: []
      )

      # Empty array is returned, not nil (see Task#normalize_artifacts)
      assert_equal [], task.artifacts
    end

    def test_handles_nil_session_id
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "submitted" },
        session_id: nil
      )

      assert_nil task.session_id
    end

    def test_handles_complex_status_message
      task = A2A::Models::Task.new(
        id: "task-123",
        status: {
          state: "working",
          message: {
            role: "agent",
            parts: [
              { type: "text", text: "Progress update:" },
              { type: "data", data: { "percent_complete" => 45 } }
            ]
          }
        }
      )

      assert_equal 2, task.status.message.parts.length
    end

    def test_handles_multiple_artifacts
      task = A2A::Models::Task.new(
        id: "task-123",
        status: { state: "completed" },
        artifacts: [
          { parts: [{ type: "text", text: "Artifact 1" }] },
          { parts: [{ type: "text", text: "Artifact 2" }] },
          { parts: [{ type: "text", text: "Artifact 3" }] }
        ]
      )

      assert_equal 3, task.artifacts.length
    end
  end

  describe "use cases" do
    def test_represents_newly_submitted_task
      task = A2A::Models::Task.new(
        id: "task-001",
        session_id: "session-abc",
        status: { state: "submitted" },
        metadata: { "created_by" => "user-123" }
      )

      assert task.state.submitted?
      assert_equal "session-abc", task.session_id
      assert_nil task.artifacts
    end

    def test_represents_task_in_progress
      task = A2A::Models::Task.new(
        id: "task-002",
        status: {
          state: "working",
          message: {
            role: "agent",
            parts: [{ type: "text", text: "Analyzing your request..." }]
          }
        }
      )

      assert task.state.working?
      assert_equal "Analyzing your request...", task.status.message.parts.first.text
    end

    def test_represents_completed_task_with_artifacts
      task = A2A::Models::Task.new(
        id: "task-003",
        status: {
          state: "completed",
          message: {
            role: "agent",
            parts: [{ type: "text", text: "Task completed successfully" }]
          }
        },
        artifacts: [
          A2A::Models::Artifact.new(
            name: "analysis_result",
            description: "Analysis of the provided data",
            parts: [
              A2A::Models::DataPart.new(
                data: {
                  "summary" => "Data looks good",
                  "score" => 95
                }
              )
            ]
          )
        ]
      )

      assert task.state.completed?
      assert_equal 1, task.artifacts.length
      assert_equal "analysis_result", task.artifacts.first.name
    end

    def test_represents_failed_task
      task = A2A::Models::Task.new(
        id: "task-004",
        status: {
          state: "failed",
          message: {
            role: "agent",
            parts: [{ type: "text", text: "Error: Invalid input format" }]
          }
        },
        metadata: { "error_code" => "E001" }
      )

      assert task.state.failed?
      assert task.state.terminal?
      assert_match(/Invalid input/, task.status.message.parts.first.text)
    end
  end
end
