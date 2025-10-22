# frozen_string_literal: true

require_relative 'test_helper'

class ErrorTest < Minitest::Test
  describe 'A2A::Error' do
    def test_is_standard_error
      assert A2A::Error < StandardError
    end

    def test_can_be_raised_and_rescued
      assert_raises(A2A::Error) do
        raise A2A::Error, 'Test error'
      end
    end

    def test_has_message
      error = A2A::Error.new('Test error message')
      assert_equal 'Test error message', error.message
    end
  end

  describe 'A2A::JSONRPCError' do
    def test_inherits_from_error
      assert A2A::JSONRPCError < A2A::Error
    end

    def test_initialization_with_all_fields
      error = A2A::JSONRPCError.new(
        'Test error',
        code: -32_001,
        data: { extra: 'info' }
      )

      assert_equal 'Test error', error.message
      assert_equal(-32_001, error.code)
      assert_equal({ extra: 'info' }, error.data)
    end

    def test_initialization_with_minimal_fields
      error = A2A::JSONRPCError.new('Test error')

      assert_equal 'Test error', error.message
      assert_nil error.code
      assert_nil error.data
    end

    def test_can_be_raised_with_code_and_data
      raise A2A::JSONRPCError.new('Error', code: -32_000, data: { reason: 'test' })
    rescue A2A::JSONRPCError => e
      assert_equal 'Error', e.message
      assert_equal(-32_000, e.code)
      assert_equal({ reason: 'test' }, e.data)
    end
  end

  describe 'A2A::JSONParseError' do
    def test_inherits_from_jsonrpc_error
      assert A2A::JSONParseError < A2A::JSONRPCError
    end

    def test_has_correct_code_and_message
      error = A2A::JSONParseError.new

      assert_equal 'Invalid JSON payload', error.message
      assert_equal(-32_700, error.code)
      assert_nil error.data
    end

    def test_accepts_optional_data
      error = A2A::JSONParseError.new(data: { position: 42 })

      assert_equal 'Invalid JSON payload', error.message
      assert_equal(-32_700, error.code)
      assert_equal({ position: 42 }, error.data)
    end

    def test_can_be_rescued_as_jsonrpc_error
      raise A2A::JSONParseError
    rescue A2A::JSONRPCError => e
      assert_equal(-32_700, e.code)
    end
  end

  describe 'A2A::InvalidRequestError' do
    def test_has_correct_code_and_message
      error = A2A::InvalidRequestError.new

      assert_equal 'Request payload validation error', error.message
      assert_equal(-32_600, error.code)
    end

    def test_accepts_optional_data
      error = A2A::InvalidRequestError.new(data: { field: 'jsonrpc' })

      assert_equal({ field: 'jsonrpc' }, error.data)
    end
  end

  describe 'A2A::MethodNotFoundError' do
    def test_has_correct_code_and_message
      error = A2A::MethodNotFoundError.new

      assert_equal 'Method not found', error.message
      assert_equal(-32_601, error.code)
    end

    def test_accepts_optional_data
      error = A2A::MethodNotFoundError.new(data: { method: 'unknown/method' })

      assert_equal({ method: 'unknown/method' }, error.data)
    end
  end

  describe 'A2A::InvalidParamsError' do
    def test_has_correct_code_and_message
      error = A2A::InvalidParamsError.new

      assert_equal 'Invalid parameters', error.message
      assert_equal(-32_602, error.code)
    end

    def test_accepts_optional_data
      error = A2A::InvalidParamsError.new(
        data: {
          errors: [
            { field: 'taskId', message: 'Required' }
          ]
        }
      )

      assert error.data[:errors].is_a?(Array)
    end
  end

  describe 'A2A::InternalError' do
    def test_has_correct_code_and_message
      error = A2A::InternalError.new

      assert_equal 'Internal error', error.message
      assert_equal(-32_603, error.code)
    end

    def test_accepts_optional_data
      error = A2A::InternalError.new(data: { stack_trace: 'line 42' })

      assert_equal({ stack_trace: 'line 42' }, error.data)
    end
  end

  describe 'A2A::TaskNotFoundError' do
    def test_has_correct_code_and_message
      error = A2A::TaskNotFoundError.new

      assert_equal 'Task not found', error.message
      assert_equal(-32_001, error.code)
      assert_nil error.data
    end

    def test_inherits_from_jsonrpc_error
      assert A2A::TaskNotFoundError < A2A::JSONRPCError
    end

    def test_can_be_raised_and_rescued
      assert_raises(A2A::TaskNotFoundError) do
        raise A2A::TaskNotFoundError
      end
    end
  end

  describe 'A2A::TaskNotCancelableError' do
    def test_has_correct_code_and_message
      error = A2A::TaskNotCancelableError.new

      assert_equal 'Task cannot be canceled', error.message
      assert_equal(-32_002, error.code)
    end
  end

  describe 'A2A::PushNotificationNotSupportedError' do
    def test_has_correct_code_and_message
      error = A2A::PushNotificationNotSupportedError.new

      assert_equal 'Push Notification is not supported', error.message
      assert_equal(-32_003, error.code)
    end
  end

  describe 'A2A::UnsupportedOperationError' do
    def test_has_correct_code_and_message
      error = A2A::UnsupportedOperationError.new

      assert_equal 'This operation is not supported', error.message
      assert_equal(-32_004, error.code)
    end
  end

  describe 'Error hierarchy' do
    def test_all_specific_errors_can_be_rescued_as_base_error
      errors = [
        A2A::JSONParseError.new,
        A2A::InvalidRequestError.new,
        A2A::MethodNotFoundError.new,
        A2A::InvalidParamsError.new,
        A2A::InternalError.new,
        A2A::TaskNotFoundError.new,
        A2A::TaskNotCancelableError.new,
        A2A::PushNotificationNotSupportedError.new,
        A2A::UnsupportedOperationError.new
      ]

      errors.each do |error|
        raise error
      rescue A2A::Error => e
        assert_instance_of error.class, e
      end
    end

    def test_error_codes_are_unique
      codes = [
        A2A::JSONParseError.new.code,
        A2A::InvalidRequestError.new.code,
        A2A::MethodNotFoundError.new.code,
        A2A::InvalidParamsError.new.code,
        A2A::InternalError.new.code,
        A2A::TaskNotFoundError.new.code,
        A2A::TaskNotCancelableError.new.code,
        A2A::PushNotificationNotSupportedError.new.code,
        A2A::UnsupportedOperationError.new.code
      ]

      assert_equal codes.length, codes.uniq.length, 'Error codes should be unique'
    end

    def test_json_rpc_standard_codes
      assert_equal(-32_700, A2A::JSONParseError.new.code)
      assert_equal(-32_600, A2A::InvalidRequestError.new.code)
      assert_equal(-32_601, A2A::MethodNotFoundError.new.code)
      assert_equal(-32_602, A2A::InvalidParamsError.new.code)
      assert_equal(-32_603, A2A::InternalError.new.code)
    end

    def test_a2a_specific_codes
      assert_equal(-32_001, A2A::TaskNotFoundError.new.code)
      assert_equal(-32_002, A2A::TaskNotCancelableError.new.code)
      assert_equal(-32_003, A2A::PushNotificationNotSupportedError.new.code)
      assert_equal(-32_004, A2A::UnsupportedOperationError.new.code)
    end

    def test_error_rescue_by_specificity
      # Can rescue specific error type
      begin
        raise A2A::TaskNotFoundError
      rescue A2A::TaskNotFoundError => e
        assert_equal(-32_001, e.code)
      rescue A2A::JSONRPCError
        flunk 'Should have been caught by more specific rescue'
      end

      # Can rescue as JSONRPCError
      begin
        raise A2A::TaskNotFoundError
      rescue A2A::JSONRPCError => e
        assert_equal(-32_001, e.code)
      end

      # Can rescue as base Error
      begin
        raise A2A::TaskNotFoundError
      rescue A2A::Error => e
        assert_equal 'Task not found', e.message
      end
    end
  end

  describe 'Error usage in protocol' do
    def test_error_can_be_converted_to_protocol_error
      exception = A2A::TaskNotFoundError.new
      protocol_error = A2A::Protocol::Error.from_exception(exception)

      assert_equal exception.code, protocol_error.code
      assert_equal exception.message, protocol_error.message
    end

    def test_multiple_errors_can_be_converted
      exceptions = [
        A2A::InvalidParamsError.new(data: { field: 'taskId' }),
        A2A::MethodNotFoundError.new(data: { method: 'tasks/unknown' }),
        A2A::InternalError.new(data: { trace: 'stack' })
      ]

      exceptions.each do |exception|
        protocol_error = A2A::Protocol::Error.from_exception(exception)

        assert_equal exception.code, protocol_error.code
        assert_equal exception.message, protocol_error.message
        assert_equal exception.data, protocol_error.data
      end
    end

    def test_protocol_error_response
      exception = A2A::TaskNotFoundError.new
      protocol_error = A2A::Protocol::Error.from_exception(exception)
      response = A2A::Protocol::Response.error(
        id: 'req-123',
        error: protocol_error.to_h
      )

      refute response.success?
      assert_equal(-32_001, response.error[:code])
      assert_equal 'Task not found', response.error[:message]
    end
  end
end
