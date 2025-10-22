# frozen_string_literal: true

module A2A
  module Protocol
    # Base class for JSON-RPC responses
    class Response
      JSONRPC_VERSION = '2.0'

      attr_reader :jsonrpc, :id, :result, :error

      def initialize(id: nil, result: nil, error: nil)
        @jsonrpc = JSONRPC_VERSION
        @id = id
        @result = result
        @error = error
      end

      def success?
        error.nil?
      end

      def to_h
        {
          jsonrpc: jsonrpc,
          id: id,
          result: result&.respond_to?(:to_h) ? result.to_h : result,
          error: error
        }.compact
      end

      def to_json(*)
        to_h.to_json(*)
      end

      def self.from_hash(hash)
        new(
          id: hash[:id] || hash['id'],
          result: hash[:result] || hash['result'],
          error: hash[:error] || hash['error']
        )
      end

      # Create a success response
      def self.success(id:, result:)
        new(id: id, result: result)
      end

      # Create an error response
      def self.error(id:, error:)
        new(id: id, error: error)
      end
    end
  end
end
