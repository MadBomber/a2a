# frozen_string_literal: true

require_relative '../test_helper'

class ProtocolErrorTest < Minitest::Test
  describe 'A2A::Protocol::Error' do
    def test_initialization_with_all_fields
      error = A2A::Protocol::Error.new(
        code: -32001,
        message: 'Task not found',
        data: { taskId: 'task-123' }
      )

      assert_equal(-32001, error.code)
      assert_equal 'Task not found', error.message
      assert_equal({ taskId: 'task-123' }, error.data)
    end

    def test_initialization_without_data
      error = A2A::Protocol::Error.new(
        code: -32600,
        message: 'Invalid request'
      )

      assert_equal(-32600, error.code)
      assert_equal 'Invalid request', error.message
      assert_nil error.data
    end

    def test_to_h_with_all_fields
      error = A2A::Protocol::Error.new(
        code: -32001,
        message: 'Task not found',
        data: { taskId: 'task-123' }
      )

      hash = error.to_h

      assert_equal(-32001, hash[:code])
      assert_equal 'Task not found', hash[:message]
      assert_equal({ taskId: 'task-123' }, hash[:data])
    end

    def test_to_h_excludes_nil_data
      error = A2A::Protocol::Error.new(
        code: -32600,
        message: 'Invalid request'
      )

      hash = error.to_h

      assert hash.key?(:code)
      assert hash.key?(:message)
      refute hash.key?(:data)
    end

    def test_from_hash_with_symbol_keys
      hash = {
        code: -32602,
        message: 'Invalid params',
        data: { field: 'taskId' }
      }

      error = A2A::Protocol::Error.from_hash(hash)

      assert_equal(-32602, error.code)
      assert_equal 'Invalid params', error.message
      assert_equal({ field: 'taskId' }, error.data)
    end

    def test_from_hash_with_string_keys
      hash = {
        'code' => -32602,
        'message' => 'Invalid params',
        'data' => { 'field' => 'taskId' }
      }

      error = A2A::Protocol::Error.from_hash(hash)

      assert_equal(-32602, error.code)
      assert_equal 'Invalid params', error.message
      assert_equal({ 'field' => 'taskId' }, error.data)
    end

    def test_from_exception_with_jsonrpc_error
      exception = A2A::TaskNotFoundError.new

      error = A2A::Protocol::Error.from_exception(exception)

      assert_equal(-32001, error.code)
      assert_equal 'Task not found', error.message
      assert_nil error.data
    end

    def test_from_exception_with_jsonrpc_error_with_data
      exception = A2A::InvalidParamsError.new(data: { field: 'message' })

      error = A2A::Protocol::Error.from_exception(exception)

      assert_equal(-32602, error.code)
      assert_equal 'Invalid parameters', error.message
      assert_equal({ field: 'message' }, error.data)
    end

    def test_from_exception_with_standard_error
      exception = StandardError.new('Something went wrong')

      error = A2A::Protocol::Error.from_exception(exception)

      assert_equal(-32603, error.code)
      assert_equal 'Something went wrong', error.message
      assert_nil error.data
    end

    def test_round_trip_serialization
      original = A2A::Protocol::Error.new(
        code: -32001,
        message: 'Task not found',
        data: { taskId: 'task-123', reason: 'expired' }
      )

      hash = original.to_h
      restored = A2A::Protocol::Error.from_hash(hash)

      assert_equal original.code, restored.code
      assert_equal original.message, restored.message
      assert_equal original.data, restored.data
    end

    def test_json_rpc_standard_error_codes
      errors = [
        { code: -32700, message: 'Parse error' },
        { code: -32600, message: 'Invalid Request' },
        { code: -32601, message: 'Method not found' },
        { code: -32602, message: 'Invalid params' },
        { code: -32603, message: 'Internal error' }
      ]

      errors.each do |error_data|
        error = A2A::Protocol::Error.new(
          code: error_data[:code],
          message: error_data[:message]
        )

        assert_equal error_data[:code], error.code
        assert_equal error_data[:message], error.message
      end
    end

    def test_a2a_specific_error_codes
      errors = [
        { code: -32001, message: 'Task not found' },
        { code: -32002, message: 'Task not cancelable' },
        { code: -32003, message: 'Push notification not supported' },
        { code: -32004, message: 'Unsupported operation' }
      ]

      errors.each do |error_data|
        error = A2A::Protocol::Error.new(
          code: error_data[:code],
          message: error_data[:message]
        )

        assert_equal error_data[:code], error.code
        assert_equal error_data[:message], error.message
      end
    end

    def test_complex_error_data
      error = A2A::Protocol::Error.new(
        code: -32602,
        message: 'Invalid params',
        data: {
          errors: [
            { field: 'message.role', message: 'Must be user or agent' },
            { field: 'message.parts', message: 'Must not be empty' }
          ]
        }
      )

      hash = error.to_h

      assert hash[:data][:errors].is_a?(Array)
      assert_equal 2, hash[:data][:errors].length
    end
  end
end
