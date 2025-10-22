# frozen_string_literal: true

require_relative '../test_helper'

class ServerBaseTest < Minitest::Test
  describe 'A2A::Server::Base' do
    def setup
      @agent_card = simple_agent_card
      @server = A2A::Server::Base.new(@agent_card)
    end

    def test_initialization
      agent_card = simple_agent_card
      server = A2A::Server::Base.new(agent_card)

      assert_equal agent_card, server.agent_card
    end

    def test_agent_card_attribute
      assert_respond_to @server, :agent_card
      assert_equal @agent_card, @server.agent_card
    end

    def test_handle_request_raises_not_implemented
      request = { method: 'tasks/send', params: {} }

      error = assert_raises(NotImplementedError) do
        @server.handle_request(request)
      end

      assert_match(/must implement #handle_request/, error.message)
    end

    def test_handle_send_task_raises_not_implemented
      params = { taskId: 'task-123' }

      error = assert_raises(NotImplementedError) do
        @server.handle_send_task(params)
      end

      assert_match(/must implement #handle_send_task/, error.message)
    end

    def test_handle_send_task_streaming_raises_not_implemented
      params = { taskId: 'task-123' }

      error = assert_raises(NotImplementedError) do
        @server.handle_send_task_streaming(params) do |event|
          # Block would handle events
        end
      end

      assert_match(/must implement #handle_send_task_streaming/, error.message)
    end

    def test_handle_get_task_raises_not_implemented
      params = { taskId: 'task-123' }

      error = assert_raises(NotImplementedError) do
        @server.handle_get_task(params)
      end

      assert_match(/must implement #handle_get_task/, error.message)
    end

    def test_handle_cancel_task_raises_not_implemented
      params = { taskId: 'task-123' }

      error = assert_raises(NotImplementedError) do
        @server.handle_cancel_task(params)
      end

      assert_match(/must implement #handle_cancel_task/, error.message)
    end

    def test_handle_set_push_notification_raises_not_implemented
      params = { taskId: 'task-123', config: {} }

      error = assert_raises(NotImplementedError) do
        @server.handle_set_push_notification(params)
      end

      assert_match(/must implement #handle_set_push_notification/, error.message)
    end

    def test_handle_get_push_notification_raises_not_implemented
      params = { taskId: 'task-123' }

      error = assert_raises(NotImplementedError) do
        @server.handle_get_push_notification(params)
      end

      assert_match(/must implement #handle_get_push_notification/, error.message)
    end

    def test_handle_resubscribe_raises_not_implemented
      params = { taskId: 'task-123' }

      error = assert_raises(NotImplementedError) do
        @server.handle_resubscribe(params) do |event|
          # Block would handle events
        end
      end

      assert_match(/must implement #handle_resubscribe/, error.message)
    end

    def test_has_all_required_methods
      required_methods = [
        :handle_request,
        :handle_send_task,
        :handle_send_task_streaming,
        :handle_get_task,
        :handle_cancel_task,
        :handle_set_push_notification,
        :handle_get_push_notification,
        :handle_resubscribe
      ]

      required_methods.each do |method|
        assert_respond_to @server, method,
          "Server should respond to #{method}"
      end
    end

    def test_subclass_can_override_methods
      # Create a concrete subclass
      concrete_server_class = Class.new(A2A::Server::Base) do
        def initialize(agent_card)
          super(agent_card)
          @tasks = {}
        end

        def handle_request(request)
          method = request[:method] || request['method']
          params = request[:params] || request['params'] || {}

          case method
          when 'tasks/send'
            { result: handle_send_task(params).to_h }
          when 'tasks/get'
            { result: handle_get_task(params).to_h }
          when 'tasks/cancel'
            { result: handle_cancel_task(params).to_h }
          else
            { error: { code: -32601, message: 'Method not found' } }
          end
        end

        def handle_send_task(params)
          task_id = params[:taskId] || params['taskId']
          task = A2A::Models::Task.new(
            id: task_id,
            status: { state: 'completed' }
          )
          @tasks[task_id] = task
          task
        end

        def handle_get_task(params)
          task_id = params[:taskId] || params['taskId']
          @tasks[task_id] || A2A::Models::Task.new(
            id: task_id,
            status: { state: 'submitted' }
          )
        end

        def handle_cancel_task(params)
          task_id = params[:taskId] || params['taskId']
          task = A2A::Models::Task.new(
            id: task_id,
            status: { state: 'canceled' }
          )
          @tasks[task_id] = task
          task
        end

        def handle_set_push_notification(params)
          true
        end

        def handle_get_push_notification(params)
          A2A::Models::PushNotificationConfig.new(
            url: 'https://webhook.example.com'
          )
        end

        def handle_send_task_streaming(params, &block)
          yield({ type: 'status', state: 'working' })
          yield({ type: 'status', state: 'completed' })
        end

        def handle_resubscribe(params, &block)
          yield({ type: 'status', state: 'working' })
        end
      end

      server = concrete_server_class.new(@agent_card)

      # Test handle_request
      response = server.handle_request(method: 'tasks/send', params: { taskId: 'task-123' })
      assert response[:result]
      assert_equal 'task-123', response[:result][:id]

      # Test handle_send_task
      task = server.handle_send_task(taskId: 'task-456')
      assert_instance_of A2A::Models::Task, task
      assert task.state.completed?

      # Test handle_get_task
      task = server.handle_get_task(taskId: 'task-456')
      assert_equal 'task-456', task.id

      # Test handle_cancel_task
      task = server.handle_cancel_task(taskId: 'task-789')
      assert task.state.canceled?

      # Test handle_set_push_notification
      result = server.handle_set_push_notification(
        taskId: 'task-123',
        config: { url: 'https://example.com' }
      )
      assert result

      # Test handle_get_push_notification
      config = server.handle_get_push_notification(taskId: 'task-123')
      assert_instance_of A2A::Models::PushNotificationConfig, config

      # Test handle_send_task_streaming
      events = []
      server.handle_send_task_streaming(taskId: 'task-123') do |event|
        events << event
      end
      assert_equal 2, events.length

      # Test handle_resubscribe
      events = []
      server.handle_resubscribe(taskId: 'task-123') do |event|
        events << event
      end
      assert_equal 1, events.length
    end

    def test_handles_method_not_found
      concrete_server_class = Class.new(A2A::Server::Base) do
        def handle_request(request)
          method = request[:method] || request['method']
          { error: { code: -32601, message: 'Method not found' } }
        end

        def handle_send_task(params)
          A2A::Models::Task.new(id: 'task-123', status: { state: 'submitted' })
        end

        def handle_get_task(params)
          A2A::Models::Task.new(id: 'task-123', status: { state: 'submitted' })
        end

        def handle_cancel_task(params)
          A2A::Models::Task.new(id: 'task-123', status: { state: 'canceled' })
        end

        def handle_set_push_notification(params); true; end
        def handle_get_push_notification(params)
          A2A::Models::PushNotificationConfig.new(url: 'https://example.com')
        end
        def handle_send_task_streaming(params, &block); end
        def handle_resubscribe(params, &block); end
      end

      server = concrete_server_class.new(@agent_card)
      response = server.handle_request(method: 'unknown/method', params: {})

      assert response[:error]
      assert_equal(-32601, response[:error][:code])
    end
  end
end
