# frozen_string_literal: true

module A2A
  module Models
    # Represents a text part in a message or artifact
    class TextPart < Part
      attr_reader :text

      def initialize(text:, metadata: nil)
        super(metadata: metadata)
        @text = text
      end

      def type
        'text'
      end

      def to_h
        super.merge(text: text)
      end

      def self.from_hash(hash)
        new(
          text: hash[:text] || hash['text'],
          metadata: hash[:metadata] || hash['metadata']
        )
      end
    end
  end
end
