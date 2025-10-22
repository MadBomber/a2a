# frozen_string_literal: true

require_relative '../test_helper'

class RequestTest < Minitest::Test
  describe 'A2A::Protocol::Request' do
    def test_initialization_with_all_fields
      request = A2A::Protocol::Request.new(
        method: 'tasks/send',
        params: { taskId: 'task-123' },
        id: 'req-456'
      )

      assert_equal '2.0', request.jsonrpc
      assert_equal 'req-456', request.id
      assert_equal 'tasks/send', request.method
      assert_equal({ taskId: 'task-123' }, request.params)
    end

    def test_initialization_minimal
      request = A2A::Protocol::Request.new(method: 'tasks/send')

      assert_equal '2.0', request.jsonrpc
      assert_equal 'tasks/send', request.method
      assert_nil request.id
      assert_nil request.params
    end

    def test_to_h_with_all_fields
      request = A2A::Protocol::Request.new(
        method: 'tasks/send',
        params: { taskId: 'task-123' },
        id: 'req-456'
      )

      hash = request.to_h

      assert_equal '2.0', hash[:jsonrpc]
      assert_equal 'req-456', hash[:id]
      assert_equal 'tasks/send', hash[:method]
      assert_equal({ taskId: 'task-123' }, hash[:params])
    end

    def test_to_h_excludes_nil_values
      request = A2A::Protocol::Request.new(method: 'tasks/send')
      hash = request.to_h

      assert hash.key?(:jsonrpc)
      assert hash.key?(:method)
      refute hash.key?(:id)
      refute hash.key?(:params)
    end

    def test_from_hash_with_symbol_keys
      hash = {
        jsonrpc: '2.0',
        id: 'req-123',
        method: 'tasks/get',
        params: { taskId: 'task-456' }
      }

      request = A2A::Protocol::Request.from_hash(hash)

      assert_equal 'req-123', request.id
      assert_equal 'tasks/get', request.method
      assert_equal({ taskId: 'task-456' }, request.params)
    end

    def test_from_hash_with_string_keys
      hash = {
        'jsonrpc' => '2.0',
        'id' => 'req-123',
        'method' => 'tasks/get',
        'params' => { 'taskId' => 'task-456' }
      }

      request = A2A::Protocol::Request.from_hash(hash)

      assert_equal 'req-123', request.id
      assert_equal 'tasks/get', request.method
      assert_equal({ 'taskId' => 'task-456' }, request.params)
    end

    def test_round_trip_serialization
      original = A2A::Protocol::Request.new(
        method: 'tasks/send',
        params: { taskId: 'task-123', message: { role: 'user' } },
        id: 'req-456'
      )

      hash = original.to_h
      restored = A2A::Protocol::Request.from_hash(hash)

      assert_equal original.method, restored.method
      assert_equal original.id, restored.id
      assert_equal original.params, restored.params
    end

    def test_various_methods
      methods = [
        'tasks/send',
        'tasks/sendSubscribe',
        'tasks/get',
        'tasks/cancel',
        'tasks/pushNotification/set',
        'tasks/pushNotification/get'
      ]

      methods.each do |method_name|
        request = A2A::Protocol::Request.new(method: method_name)
        assert_equal method_name, request.method
      end
    end

    def test_complex_params
      request = A2A::Protocol::Request.new(
        method: 'tasks/send',
        params: {
          taskId: 'task-123',
          sessionId: 'session-456',
          message: {
            role: 'user',
            parts: [
              { type: 'text', text: 'Hello' },
              { type: 'data', data: { count: 42 } }
            ]
          }
        }
      )

      hash = request.to_h
      assert hash[:params][:message]
      assert_equal 2, hash[:params][:message][:parts].length
    end

    def test_notification_request_without_id
      # Notifications in JSON-RPC don't have an id
      request = A2A::Protocol::Request.new(method: 'notification')
      hash = request.to_h

      refute hash.key?(:id)
      assert_equal 'notification', hash[:method]
    end
  end
end
