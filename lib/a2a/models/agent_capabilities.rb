# frozen_string_literal: true

module A2A
  module Models
    # Represents the capabilities supported by an agent
    class AgentCapabilities
      attr_reader :streaming, :push_notifications, :state_transition_history

      def initialize(streaming: false, push_notifications: false, state_transition_history: false)
        @streaming = streaming
        @push_notifications = push_notifications
        @state_transition_history = state_transition_history
      end

      def streaming?
        @streaming
      end

      def push_notifications?
        @push_notifications
      end

      def state_transition_history?
        @state_transition_history
      end

      def to_h
        {
          streaming: streaming,
          pushNotifications: push_notifications,
          stateTransitionHistory: state_transition_history
        }
      end

      def to_json(*)
        to_h.to_json(*)
      end

      def self.from_hash(hash)
        new(
          streaming: hash[:streaming] || hash['streaming'] || false,
          push_notifications: hash[:pushNotifications] || hash['pushNotifications'] || hash[:push_notifications] || false,
          state_transition_history: hash[:stateTransitionHistory] || hash['stateTransitionHistory'] || hash[:state_transition_history] || false
        )
      end
    end
  end
end
