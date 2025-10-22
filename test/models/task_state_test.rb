# frozen_string_literal: true

require "test_helper"

class TaskStateTest < Minitest::Test
  describe "initialization" do
    def test_creates_task_state_with_valid_state
      state = A2A::Models::TaskState.new("submitted")
      assert_equal "submitted", state.value
    end

    def test_raises_error_for_invalid_state
      error = assert_raises(ArgumentError) do
        A2A::Models::TaskState.new("invalid")
      end
      assert_match(/Invalid task state/, error.message)
      assert_match(/Must be one of/, error.message)
    end

    def test_accepts_all_valid_states
      A2A::Models::TaskState::STATES.each do |state_value|
        state = A2A::Models::TaskState.new(state_value)
        assert_equal state_value, state.value
      end
    end
  end

  describe "string conversion" do
    def test_to_s_returns_state_value
      state = A2A::Models::TaskState.new("working")
      assert_equal "working", state.to_s
    end

    def test_to_json_returns_state_value
      state = A2A::Models::TaskState.new("completed")
      assert_equal "completed", state.to_json
    end
  end

  describe "equality" do
    def test_equal_states_are_equal
      state1 = A2A::Models::TaskState.new("submitted")
      state2 = A2A::Models::TaskState.new("submitted")
      assert_equal state1, state2
    end

    def test_different_states_are_not_equal
      state1 = A2A::Models::TaskState.new("submitted")
      state2 = A2A::Models::TaskState.new("working")
      refute_equal state1, state2
    end

    def test_returns_false_for_non_task_state_objects
      state = A2A::Models::TaskState.new("submitted")
      refute_equal state, "submitted"
      refute_equal state, nil
    end
  end

  describe "state helper methods" do
    def test_submitted_predicate
      state = A2A::Models::TaskState.new("submitted")
      assert state.submitted?
      refute state.working?
    end

    def test_working_predicate
      state = A2A::Models::TaskState.new("working")
      assert state.working?
      refute state.submitted?
    end

    def test_input_required_predicate
      state = A2A::Models::TaskState.new("input-required")
      assert state.input_required?
      refute state.working?
    end

    def test_completed_predicate
      state = A2A::Models::TaskState.new("completed")
      assert state.completed?
      refute state.working?
    end

    def test_canceled_predicate
      state = A2A::Models::TaskState.new("canceled")
      assert state.canceled?
      refute state.completed?
    end

    def test_failed_predicate
      state = A2A::Models::TaskState.new("failed")
      assert state.failed?
      refute state.completed?
    end

    def test_unknown_predicate
      state = A2A::Models::TaskState.new("unknown")
      assert state.unknown?
      refute state.failed?
    end
  end

  describe "terminal state detection" do
    def test_completed_is_terminal
      state = A2A::Models::TaskState.new("completed")
      assert state.terminal?
    end

    def test_canceled_is_terminal
      state = A2A::Models::TaskState.new("canceled")
      assert state.terminal?
    end

    def test_failed_is_terminal
      state = A2A::Models::TaskState.new("failed")
      assert state.terminal?
    end

    def test_submitted_is_not_terminal
      state = A2A::Models::TaskState.new("submitted")
      refute state.terminal?
    end

    def test_working_is_not_terminal
      state = A2A::Models::TaskState.new("working")
      refute state.terminal?
    end

    def test_input_required_is_not_terminal
      state = A2A::Models::TaskState.new("input-required")
      refute state.terminal?
    end

    def test_unknown_is_not_terminal
      state = A2A::Models::TaskState.new("unknown")
      refute state.terminal?
    end
  end

  describe "STATES constant" do
    def test_states_constant_includes_all_valid_states
      expected_states = %w[submitted working input-required completed canceled failed unknown]
      assert_equal expected_states, A2A::Models::TaskState::STATES
    end

    def test_states_constant_is_frozen
      assert A2A::Models::TaskState::STATES.frozen?
    end
  end
end
