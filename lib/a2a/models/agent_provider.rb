# frozen_string_literal: true

module A2A
  module Models
    # Represents the provider information for an agent
    class AgentProvider
      attr_reader :organization, :url

      def initialize(organization:, url: nil)
        @organization = organization
        @url = url
      end

      def to_h
        {
          organization: organization,
          url: url
        }.compact
      end

      def to_json(*args)
        to_h.to_json(*args)
      end

      def self.from_hash(hash)
        new(
          organization: hash[:organization] || hash['organization'],
          url: hash[:url] || hash['url']
        )
      end
    end
  end
end
