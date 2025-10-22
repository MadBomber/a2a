# frozen_string_literal: true

module A2A
  module Client
    # Base class for A2A clients
    # An A2A client consumes A2A services by sending requests to an A2A server
    class Base
      attr_reader :agent_url, :agent_card

      def initialize(agent_url)
        @agent_url = agent_url
        @agent_card = nil
      end

      # Discover the agent by fetching its AgentCard from /.well-known/agent.json
      def discover
        raise NotImplementedError, "Subclasses must implement #discover"
      end

      # Send a task to the agent
      # @param task_id [String] Unique task identifier
      # @param message [A2A::Models::Message] The message to send
      # @param session_id [String, nil] Optional session ID for multi-turn conversations
      # @return [A2A::Models::Task] The task response
      def send_task(task_id:, message:, session_id: nil)
        raise NotImplementedError, "Subclasses must implement #send_task"
      end

      # Send a task with streaming support
      # @param task_id [String] Unique task identifier
      # @param message [A2A::Models::Message] The message to send
      # @param session_id [String, nil] Optional session ID
      # @yield [event] Yields task status and artifact update events
      def send_task_streaming(task_id:, message:, session_id: nil, &block)
        raise NotImplementedError, "Subclasses must implement #send_task_streaming"
      end

      # Get the current status of a task
      # @param task_id [String] The task identifier
      # @return [A2A::Models::Task] The task
      def get_task(task_id:)
        raise NotImplementedError, "Subclasses must implement #get_task"
      end

      # Cancel a task
      # @param task_id [String] The task identifier
      # @return [A2A::Models::Task] The canceled task
      def cancel_task(task_id:)
        raise NotImplementedError, "Subclasses must implement #cancel_task"
      end

      # Set push notification configuration for a task
      # @param task_id [String] The task identifier
      # @param config [A2A::Models::PushNotificationConfig] The push notification configuration
      def set_push_notification(task_id:, config:)
        raise NotImplementedError, "Subclasses must implement #set_push_notification"
      end

      # Get push notification configuration for a task
      # @param task_id [String] The task identifier
      # @return [A2A::Models::PushNotificationConfig] The configuration
      def get_push_notification(task_id:)
        raise NotImplementedError, "Subclasses must implement #get_push_notification"
      end
    end
  end
end
