# frozen_string_literal: true

require_relative 'part'
require_relative 'text_part'
require_relative 'file_part'
require_relative 'data_part'

module A2A
  module Models
    # Represents communication turns between the client (role: "user") and the agent (role: "agent")
    # Messages contain Parts
    class Message
      ROLES = %w[user agent].freeze

      attr_reader :role, :parts, :metadata

      def initialize(role:, parts:, metadata: nil)
        validate_role(role)

        @role = role
        @parts = normalize_parts(parts)
        @metadata = metadata
      end

      def to_h
        {
          role: role,
          parts: parts.map(&:to_h),
          metadata: metadata
        }.compact
      end

      def to_json(*args)
        to_h.to_json(*args)
      end

      def self.from_hash(hash)
        new(
          role: hash[:role] || hash['role'],
          parts: (hash[:parts] || hash['parts']).map { |p| Part.from_hash(p) },
          metadata: hash[:metadata] || hash['metadata']
        )
      end

      # Convenience constructor for text messages
      def self.text(role:, text:, metadata: nil)
        new(
          role: role,
          parts: [TextPart.new(text: text)],
          metadata: metadata
        )
      end

      private

      def validate_role(role)
        unless ROLES.include?(role)
          raise ArgumentError, "Invalid role: #{role}. Must be one of: #{ROLES.join(', ')}"
        end
      end

      def normalize_parts(parts)
        parts.map do |part|
          part.is_a?(Part) ? part : Part.from_hash(part)
        end
      end
    end
  end
end
