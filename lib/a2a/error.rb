# frozen_string_literal: true

module A2A
  # Base error class for all A2A errors
  class Error < StandardError; end

  # JSON-RPC protocol errors
  class JSONRPCError < Error
    attr_reader :code, :data

    def initialize(message, code: nil, data: nil)
      super(message)
      @code = code
      @data = data
    end
  end

  # Specific A2A protocol errors based on JSON-RPC error codes
  class JSONParseError < JSONRPCError
    def initialize(data: nil)
      super('Invalid JSON payload', code: -32700, data: data)
    end
  end

  class InvalidRequestError < JSONRPCError
    def initialize(data: nil)
      super('Request payload validation error', code: -32600, data: data)
    end
  end

  class MethodNotFoundError < JSONRPCError
    def initialize(data: nil)
      super('Method not found', code: -32601, data: data)
    end
  end

  class InvalidParamsError < JSONRPCError
    def initialize(data: nil)
      super('Invalid parameters', code: -32602, data: data)
    end
  end

  class InternalError < JSONRPCError
    def initialize(data: nil)
      super('Internal error', code: -32603, data: data)
    end
  end

  # A2A-specific errors
  class TaskNotFoundError < JSONRPCError
    def initialize
      super('Task not found', code: -32001, data: nil)
    end
  end

  class TaskNotCancelableError < JSONRPCError
    def initialize
      super('Task cannot be canceled', code: -32002, data: nil)
    end
  end

  class PushNotificationNotSupportedError < JSONRPCError
    def initialize
      super('Push Notification is not supported', code: -32003, data: nil)
    end
  end

  class UnsupportedOperationError < JSONRPCError
    def initialize
      super('This operation is not supported', code: -32004, data: nil)
    end
  end
end
