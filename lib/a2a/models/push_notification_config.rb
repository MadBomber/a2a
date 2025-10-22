# frozen_string_literal: true

module A2A
  module Models
    # Represents push notification configuration
    class PushNotificationConfig
      attr_reader :url, :token, :authentication

      def initialize(url:, token: nil, authentication: nil)
        @url = url
        @token = token
        @authentication = authentication
      end

      def to_h
        {
          url: url,
          token: token,
          authentication: authentication
        }.compact
      end

      def to_json(*)
        to_h.to_json(*)
      end

      def self.from_hash(hash)
        new(
          url: hash[:url] || hash['url'],
          token: hash[:token] || hash['token'],
          authentication: hash[:authentication] || hash['authentication']
        )
      end
    end
  end
end
