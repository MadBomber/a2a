# frozen_string_literal: true

module A2A
  module Protocol
    # Base class for JSON-RPC requests
    class Request
      JSONRPC_VERSION = '2.0'

      attr_reader :jsonrpc, :id, :method, :params

      def initialize(method:, params: nil, id: nil)
        @jsonrpc = JSONRPC_VERSION
        @id = id
        @method = method
        @params = params
      end

      def to_h
        {
          jsonrpc: jsonrpc,
          id: id,
          method: method,
          params: params
        }.compact
      end

      def to_json(*)
        to_h.to_json(*)
      end

      def self.from_hash(hash)
        new(
          method: hash[:method] || hash['method'],
          params: hash[:params] || hash['params'],
          id: hash[:id] || hash['id']
        )
      end
    end
  end
end
