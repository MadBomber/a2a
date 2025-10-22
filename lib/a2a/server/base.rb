# frozen_string_literal: true

module A2A
  module Server
    # Base class for A2A servers
    # An A2A server exposes an HTTP endpoint that implements the A2A protocol methods
    class Base
      attr_reader :agent_card

      def initialize(agent_card)
        @agent_card = agent_card
      end

      # Handle an incoming A2A request
      # @param request [Hash] The JSON-RPC request
      # @return [Hash] The JSON-RPC response
      def handle_request(request)
        raise NotImplementedError, "Subclasses must implement #handle_request"
      end

      # Handle tasks/send request
      # @param params [Hash] The request parameters
      # @return [A2A::Models::Task] The task
      def handle_send_task(params)
        raise NotImplementedError, "Subclasses must implement #handle_send_task"
      end

      # Handle tasks/sendSubscribe request (streaming)
      # @param params [Hash] The request parameters
      # @yield [event] Yields task status and artifact update events
      def handle_send_task_streaming(params, &)
        raise NotImplementedError, "Subclasses must implement #handle_send_task_streaming"
      end

      # Handle tasks/get request
      # @param params [Hash] The request parameters
      # @return [A2A::Models::Task] The task
      def handle_get_task(params)
        raise NotImplementedError, "Subclasses must implement #handle_get_task"
      end

      # Handle tasks/cancel request
      # @param params [Hash] The request parameters
      # @return [A2A::Models::Task] The canceled task
      def handle_cancel_task(params)
        raise NotImplementedError, "Subclasses must implement #handle_cancel_task"
      end

      # Handle tasks/pushNotification/set request
      # @param params [Hash] The request parameters
      def handle_set_push_notification(params)
        raise NotImplementedError, "Subclasses must implement #handle_set_push_notification"
      end

      # Handle tasks/pushNotification/get request
      # @param params [Hash] The request parameters
      # @return [A2A::Models::PushNotificationConfig] The configuration
      def handle_get_push_notification(params)
        raise NotImplementedError, "Subclasses must implement #handle_get_push_notification"
      end

      # Handle tasks/resubscribe request
      # @param params [Hash] The request parameters
      # @yield [event] Yields task status and artifact update events
      def handle_resubscribe(params, &)
        raise NotImplementedError, "Subclasses must implement #handle_resubscribe"
      end
    end
  end
end
