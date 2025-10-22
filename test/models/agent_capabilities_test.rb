# frozen_string_literal: true

require "test_helper"

class AgentCapabilitiesTest < Minitest::Test
  describe "initialization" do
    def test_creates_agent_capabilities_with_default_values
      caps = A2A::Models::AgentCapabilities.new

      assert_equal false, caps.streaming
      assert_equal false, caps.push_notifications
      assert_equal false, caps.state_transition_history
    end

    def test_creates_agent_capabilities_with_streaming
      caps = A2A::Models::AgentCapabilities.new(streaming: true)

      assert_equal true, caps.streaming
      assert_equal false, caps.push_notifications
      assert_equal false, caps.state_transition_history
    end

    def test_creates_agent_capabilities_with_push_notifications
      caps = A2A::Models::AgentCapabilities.new(push_notifications: true)

      assert_equal false, caps.streaming
      assert_equal true, caps.push_notifications
    end

    def test_creates_agent_capabilities_with_state_transition_history
      caps = A2A::Models::AgentCapabilities.new(state_transition_history: true)

      assert_equal false, caps.streaming
      assert_equal true, caps.state_transition_history
    end

    def test_creates_agent_capabilities_with_all_enabled
      caps = A2A::Models::AgentCapabilities.new(
        streaming: true,
        push_notifications: true,
        state_transition_history: true
      )

      assert_equal true, caps.streaming
      assert_equal true, caps.push_notifications
      assert_equal true, caps.state_transition_history
    end

    def test_creates_agent_capabilities_with_all_disabled
      caps = A2A::Models::AgentCapabilities.new(
        streaming: false,
        push_notifications: false,
        state_transition_history: false
      )

      assert_equal false, caps.streaming
      assert_equal false, caps.push_notifications
      assert_equal false, caps.state_transition_history
    end
  end

  describe "predicate methods" do
    def test_streaming_predicate
      caps_enabled = A2A::Models::AgentCapabilities.new(streaming: true)
      assert caps_enabled.streaming?

      caps_disabled = A2A::Models::AgentCapabilities.new(streaming: false)
      refute caps_disabled.streaming?
    end

    def test_push_notifications_predicate
      caps_enabled = A2A::Models::AgentCapabilities.new(push_notifications: true)
      assert caps_enabled.push_notifications?

      caps_disabled = A2A::Models::AgentCapabilities.new(push_notifications: false)
      refute caps_disabled.push_notifications?
    end

    def test_state_transition_history_predicate
      caps_enabled = A2A::Models::AgentCapabilities.new(state_transition_history: true)
      assert caps_enabled.state_transition_history?

      caps_disabled = A2A::Models::AgentCapabilities.new(state_transition_history: false)
      refute caps_disabled.state_transition_history?
    end
  end

  describe "to_h" do
    def test_to_h_with_default_values
      caps = A2A::Models::AgentCapabilities.new
      hash = caps.to_h

      assert_equal false, hash[:streaming]
      assert_equal false, hash[:pushNotifications]
      assert_equal false, hash[:stateTransitionHistory]
    end

    def test_to_h_with_streaming_enabled
      caps = A2A::Models::AgentCapabilities.new(streaming: true)
      hash = caps.to_h

      assert_equal true, hash[:streaming]
      assert_equal false, hash[:pushNotifications]
    end

    def test_to_h_with_all_capabilities_enabled
      caps = A2A::Models::AgentCapabilities.new(
        streaming: true,
        push_notifications: true,
        state_transition_history: true
      )
      hash = caps.to_h

      assert_equal true, hash[:streaming]
      assert_equal true, hash[:pushNotifications]
      assert_equal true, hash[:stateTransitionHistory]
    end

    def test_to_h_uses_camel_case_keys
      caps = A2A::Models::AgentCapabilities.new(
        push_notifications: true,
        state_transition_history: true
      )
      hash = caps.to_h

      assert hash.key?(:pushNotifications)
      refute hash.key?(:push_notifications)
      assert hash.key?(:stateTransitionHistory)
      refute hash.key?(:state_transition_history)
    end

    def test_to_h_includes_false_values
      caps = A2A::Models::AgentCapabilities.new(
        streaming: false,
        push_notifications: false
      )
      hash = caps.to_h

      assert hash.key?(:streaming)
      assert hash.key?(:pushNotifications)
      assert_equal false, hash[:streaming]
      assert_equal false, hash[:pushNotifications]
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        streaming: true,
        pushNotifications: true,
        stateTransitionHistory: false
      }
      caps = A2A::Models::AgentCapabilities.from_hash(hash)

      assert_equal true, caps.streaming
      assert_equal true, caps.push_notifications
      assert_equal false, caps.state_transition_history
    end

    def test_from_hash_with_string_keys
      hash = {
        "streaming" => true,
        "pushNotifications" => false,
        "stateTransitionHistory" => true
      }
      caps = A2A::Models::AgentCapabilities.from_hash(hash)

      assert_equal true, caps.streaming
      assert_equal false, caps.push_notifications
      assert_equal true, caps.state_transition_history
    end

    def test_from_hash_with_snake_case_keys
      hash = {
        push_notifications: true,
        state_transition_history: true
      }
      caps = A2A::Models::AgentCapabilities.from_hash(hash)

      assert_equal true, caps.push_notifications
      assert_equal true, caps.state_transition_history
    end

    def test_from_hash_with_missing_keys_defaults_to_false
      hash = { streaming: true }
      caps = A2A::Models::AgentCapabilities.from_hash(hash)

      assert_equal true, caps.streaming
      assert_equal false, caps.push_notifications
      assert_equal false, caps.state_transition_history
    end

    def test_from_hash_with_empty_hash_defaults_to_false
      caps = A2A::Models::AgentCapabilities.from_hash({})

      assert_equal false, caps.streaming
      assert_equal false, caps.push_notifications
      assert_equal false, caps.state_transition_history
    end

    def test_from_hash_prefers_camel_case_over_snake_case
      hash = {
        pushNotifications: true,
        push_notifications: false
      }
      caps = A2A::Models::AgentCapabilities.from_hash(hash)

      assert_equal true, caps.push_notifications
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_default_values
      original = A2A::Models::AgentCapabilities.new

      hash = original.to_h
      restored = A2A::Models::AgentCapabilities.from_hash(hash)

      assert_equal original.streaming, restored.streaming
      assert_equal original.push_notifications, restored.push_notifications
      assert_equal original.state_transition_history, restored.state_transition_history
    end

    def test_round_trip_with_all_enabled
      original = A2A::Models::AgentCapabilities.new(
        streaming: true,
        push_notifications: true,
        state_transition_history: true
      )

      hash = original.to_h
      restored = A2A::Models::AgentCapabilities.from_hash(hash)

      assert_equal original.streaming, restored.streaming
      assert_equal original.push_notifications, restored.push_notifications
      assert_equal original.state_transition_history, restored.state_transition_history
    end

    def test_round_trip_with_mixed_values
      original = A2A::Models::AgentCapabilities.new(
        streaming: true,
        push_notifications: false,
        state_transition_history: true
      )

      hash = original.to_h
      restored = A2A::Models::AgentCapabilities.from_hash(hash)

      assert_equal original.streaming, restored.streaming
      assert_equal original.push_notifications, restored.push_notifications
      assert_equal original.state_transition_history, restored.state_transition_history
    end
  end

  describe "use cases" do
    def test_represents_basic_agent
      caps = A2A::Models::AgentCapabilities.new

      refute caps.streaming?
      refute caps.push_notifications?
      refute caps.state_transition_history?
    end

    def test_represents_streaming_agent
      caps = A2A::Models::AgentCapabilities.new(streaming: true)

      assert caps.streaming?
      refute caps.push_notifications?
    end

    def test_represents_agent_with_push_notifications
      caps = A2A::Models::AgentCapabilities.new(
        streaming: true,
        push_notifications: true
      )

      assert caps.streaming?
      assert caps.push_notifications?
    end

    def test_represents_fully_featured_agent
      caps = A2A::Models::AgentCapabilities.new(
        streaming: true,
        push_notifications: true,
        state_transition_history: true
      )

      assert caps.streaming?
      assert caps.push_notifications?
      assert caps.state_transition_history?
    end

    def test_represents_audit_enabled_agent
      caps = A2A::Models::AgentCapabilities.new(
        state_transition_history: true
      )

      refute caps.streaming?
      assert caps.state_transition_history?
    end
  end

  describe "edge cases" do
    def test_handles_nil_values_as_false
      caps = A2A::Models::AgentCapabilities.new(
        streaming: nil,
        push_notifications: nil,
        state_transition_history: nil
      )

      refute caps.streaming
      refute caps.push_notifications
      refute caps.state_transition_history
    end

    def test_handles_truthy_values
      caps = A2A::Models::AgentCapabilities.new(
        streaming: "yes",
        push_notifications: 1,
        state_transition_history: []
      )

      assert caps.streaming
      assert caps.push_notifications
      assert caps.state_transition_history
    end
  end

  describe "attribute accessors" do
    def test_streaming_reader
      caps = A2A::Models::AgentCapabilities.new(streaming: true)
      assert_equal true, caps.streaming
    end

    def test_push_notifications_reader
      caps = A2A::Models::AgentCapabilities.new(push_notifications: true)
      assert_equal true, caps.push_notifications
    end

    def test_state_transition_history_reader
      caps = A2A::Models::AgentCapabilities.new(state_transition_history: true)
      assert_equal true, caps.state_transition_history
    end
  end
end
