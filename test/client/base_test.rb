# frozen_string_literal: true

require_relative '../test_helper'

class ClientBaseTest < Minitest::Test
  describe 'A2A::Client::Base' do
    def setup
      @client = A2A::Client::Base.new('https://agent.example.com/a2a')
    end

    def test_initialization
      client = A2A::Client::Base.new('https://agent.example.com/a2a')

      assert_equal 'https://agent.example.com/a2a', client.agent_url
      assert_nil client.agent_card
    end

    def test_agent_url_attribute
      assert_respond_to @client, :agent_url
      assert_equal 'https://agent.example.com/a2a', @client.agent_url
    end

    def test_agent_card_attribute
      assert_respond_to @client, :agent_card
      assert_nil @client.agent_card
    end

    def test_discover_raises_not_implemented
      error = assert_raises(NotImplementedError) do
        @client.discover
      end

      assert_match(/must implement #discover/, error.message)
    end

    def test_send_task_raises_not_implemented
      message = simple_text_message

      error = assert_raises(NotImplementedError) do
        @client.send_task(task_id: 'task-123', message: message)
      end

      assert_match(/must implement #send_task/, error.message)
    end

    def test_send_task_accepts_session_id
      message = simple_text_message

      error = assert_raises(NotImplementedError) do
        @client.send_task(
          task_id: 'task-123',
          message: message,
          session_id: 'session-456'
        )
      end

      assert_match(/must implement #send_task/, error.message)
    end

    def test_send_task_streaming_raises_not_implemented
      message = simple_text_message

      error = assert_raises(NotImplementedError) do
        @client.send_task_streaming(task_id: 'task-123', message: message) do |event|
          # Block would handle events
        end
      end

      assert_match(/must implement #send_task_streaming/, error.message)
    end

    def test_get_task_raises_not_implemented
      error = assert_raises(NotImplementedError) do
        @client.get_task(task_id: 'task-123')
      end

      assert_match(/must implement #get_task/, error.message)
    end

    def test_cancel_task_raises_not_implemented
      error = assert_raises(NotImplementedError) do
        @client.cancel_task(task_id: 'task-123')
      end

      assert_match(/must implement #cancel_task/, error.message)
    end

    def test_set_push_notification_raises_not_implemented
      config = A2A::Models::PushNotificationConfig.new(
        url: 'https://webhook.example.com/notify'
      )

      error = assert_raises(NotImplementedError) do
        @client.set_push_notification(task_id: 'task-123', config: config)
      end

      assert_match(/must implement #set_push_notification/, error.message)
    end

    def test_get_push_notification_raises_not_implemented
      error = assert_raises(NotImplementedError) do
        @client.get_push_notification(task_id: 'task-123')
      end

      assert_match(/must implement #get_push_notification/, error.message)
    end

    def test_has_all_required_methods
      required_methods = [
        :discover,
        :send_task,
        :send_task_streaming,
        :get_task,
        :cancel_task,
        :set_push_notification,
        :get_push_notification
      ]

      required_methods.each do |method|
        assert_respond_to @client, method,
          "Client should respond to #{method}"
      end
    end

    def test_subclass_can_override_methods
      # Create a concrete subclass
      concrete_client_class = Class.new(A2A::Client::Base) do
        def discover
          @agent_card = A2A::Models::AgentCard.new(
            name: 'Test Agent',
            url: agent_url,
            version: '1.0.0',
            capabilities: { streaming: false },
            skills: []
          )
        end

        def send_task(task_id:, message:, session_id: nil)
          A2A::Models::Task.new(
            id: task_id,
            session_id: session_id,
            status: { state: 'completed' }
          )
        end

        def get_task(task_id:)
          A2A::Models::Task.new(
            id: task_id,
            status: { state: 'submitted' }
          )
        end

        def cancel_task(task_id:)
          A2A::Models::Task.new(
            id: task_id,
            status: { state: 'canceled' }
          )
        end

        def set_push_notification(task_id:, config:)
          true
        end

        def get_push_notification(task_id:)
          A2A::Models::PushNotificationConfig.new(
            url: 'https://webhook.example.com'
          )
        end

        def send_task_streaming(task_id:, message:, session_id: nil, &block)
          yield({ type: 'status', data: { state: 'working' } })
          yield({ type: 'completed', data: { state: 'completed' } })
        end
      end

      client = concrete_client_class.new('https://test.example.com/a2a')

      # Test that overridden methods work
      client.discover
      assert_instance_of A2A::Models::AgentCard, client.agent_card

      task = client.send_task(
        task_id: 'task-123',
        message: simple_text_message
      )
      assert_instance_of A2A::Models::Task, task
      assert_equal 'task-123', task.id

      task = client.get_task(task_id: 'task-456')
      assert_equal 'task-456', task.id
      assert task.state.submitted?

      task = client.cancel_task(task_id: 'task-789')
      assert task.state.canceled?

      result = client.set_push_notification(
        task_id: 'task-123',
        config: A2A::Models::PushNotificationConfig.new(url: 'https://example.com')
      )
      assert result

      config = client.get_push_notification(task_id: 'task-123')
      assert_instance_of A2A::Models::PushNotificationConfig, config

      events = []
      client.send_task_streaming(
        task_id: 'task-123',
        message: simple_text_message
      ) do |event|
        events << event
      end
      assert_equal 2, events.length
    end
  end
end
