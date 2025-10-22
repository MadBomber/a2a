# frozen_string_literal: true

module A2A
  module Models
    # Represents authentication configuration for an agent
    class AgentAuthentication
      attr_reader :schemes, :credentials

      def initialize(schemes:, credentials: nil)
        @schemes = schemes
        @credentials = credentials
      end

      def to_h
        {
          schemes: schemes,
          credentials: credentials
        }.compact
      end

      def to_json(*)
        to_h.to_json(*)
      end

      def self.from_hash(hash)
        new(
          schemes: hash[:schemes] || hash['schemes'],
          credentials: hash[:credentials] || hash['credentials']
        )
      end
    end
  end
end
