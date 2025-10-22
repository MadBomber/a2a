# frozen_string_literal: true

module A2A
  module Protocol
    # Represents a JSON-RPC error in a protocol message
    class Error
      attr_reader :code, :message, :data

      def initialize(code:, message:, data: nil)
        @code = code
        @message = message
        @data = data
      end

      def to_h
        {
          code: code,
          message: message,
          data: data
        }.compact
      end

      def to_json(*)
        to_h.to_json(*)
      end

      def self.from_hash(hash)
        new(
          code: hash[:code] || hash['code'],
          message: hash[:message] || hash['message'],
          data: hash[:data] || hash['data']
        )
      end

      # Create error from an exception
      def self.from_exception(exception)
        case exception
        when A2A::JSONRPCError
          new(code: exception.code, message: exception.message, data: exception.data)
        else
          new(code: -32_603, message: exception.message)
        end
      end
    end
  end
end
