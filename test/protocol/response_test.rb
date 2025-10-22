# frozen_string_literal: true

require_relative '../test_helper'

class ResponseTest < Minitest::Test
  describe 'A2A::Protocol::Response' do
    def test_initialization_with_result
      response = A2A::Protocol::Response.new(
        id: 'req-123',
        result: { status: 'ok' }
      )

      assert_equal '2.0', response.jsonrpc
      assert_equal 'req-123', response.id
      assert_equal({ status: 'ok' }, response.result)
      assert_nil response.error
    end

    def test_initialization_with_error
      error = { code: -32001, message: 'Task not found' }
      response = A2A::Protocol::Response.new(
        id: 'req-123',
        error: error
      )

      assert_equal '2.0', response.jsonrpc
      assert_equal 'req-123', response.id
      assert_equal error, response.error
      assert_nil response.result
    end

    def test_success_predicate
      success_response = A2A::Protocol::Response.new(
        id: 'req-123',
        result: { status: 'ok' }
      )

      assert success_response.success?

      error_response = A2A::Protocol::Response.new(
        id: 'req-123',
        error: { code: -32001, message: 'Error' }
      )

      refute error_response.success?
    end

    def test_success_factory_method
      response = A2A::Protocol::Response.success(
        id: 'req-123',
        result: { data: [1, 2, 3] }
      )

      assert response.success?
      assert_equal 'req-123', response.id
      assert_equal({ data: [1, 2, 3] }, response.result)
      assert_nil response.error
    end

    def test_error_factory_method
      error = { code: -32001, message: 'Task not found' }
      response = A2A::Protocol::Response.error(
        id: 'req-123',
        error: error
      )

      refute response.success?
      assert_equal 'req-123', response.id
      assert_equal error, response.error
      assert_nil response.result
    end

    def test_to_h_with_result
      response = A2A::Protocol::Response.new(
        id: 'req-123',
        result: { status: 'completed' }
      )

      hash = response.to_h

      assert_equal '2.0', hash[:jsonrpc]
      assert_equal 'req-123', hash[:id]
      assert_equal({ status: 'completed' }, hash[:result])
      refute hash.key?(:error)
    end

    def test_to_h_with_error
      error = { code: -32001, message: 'Task not found' }
      response = A2A::Protocol::Response.new(
        id: 'req-123',
        error: error
      )

      hash = response.to_h

      assert_equal '2.0', hash[:jsonrpc]
      assert_equal 'req-123', hash[:id]
      assert_equal error, hash[:error]
      refute hash.key?(:result)
    end

    def test_to_h_with_object_result
      task = simple_task(id: 'task-123', state: 'completed')
      response = A2A::Protocol::Response.new(
        id: 'req-456',
        result: task
      )

      hash = response.to_h

      assert hash[:result].is_a?(Hash)
      assert_equal 'task-123', hash[:result][:id]
    end

    def test_from_hash_with_symbol_keys
      hash = {
        jsonrpc: '2.0',
        id: 'req-123',
        result: { status: 'ok' }
      }

      response = A2A::Protocol::Response.from_hash(hash)

      assert_equal 'req-123', response.id
      assert_equal({ status: 'ok' }, response.result)
      assert_nil response.error
    end

    def test_from_hash_with_string_keys
      hash = {
        'jsonrpc' => '2.0',
        'id' => 'req-123',
        'error' => { 'code' => -32001, 'message' => 'Error' }
      }

      response = A2A::Protocol::Response.from_hash(hash)

      assert_equal 'req-123', response.id
      assert_equal({ 'code' => -32001, 'message' => 'Error' }, response.error)
      assert_nil response.result
    end

    def test_round_trip_serialization_with_result
      original = A2A::Protocol::Response.new(
        id: 'req-123',
        result: { data: { count: 42 } }
      )

      hash = original.to_h
      restored = A2A::Protocol::Response.from_hash(hash)

      assert_equal original.id, restored.id
      assert_equal original.result, restored.result
      assert_equal original.error, restored.error
    end

    def test_round_trip_serialization_with_error
      original = A2A::Protocol::Response.new(
        id: 'req-123',
        error: { code: -32001, message: 'Task not found', data: { taskId: 'task-456' } }
      )

      hash = original.to_h
      restored = A2A::Protocol::Response.from_hash(hash)

      assert_equal original.id, restored.id
      assert_equal original.error, restored.error
      assert_equal original.result, restored.result
    end

    def test_complex_result
      result = {
        task: {
          id: 'task-123',
          status: { state: 'completed' },
          artifacts: [
            {
              name: 'Result',
              parts: [
                { type: 'text', text: 'Done!' }
              ]
            }
          ]
        }
      }

      response = A2A::Protocol::Response.new(id: 'req-456', result: result)
      hash = response.to_h

      assert_equal result, hash[:result]
    end
  end
end
