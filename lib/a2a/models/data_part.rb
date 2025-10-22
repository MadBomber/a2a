# frozen_string_literal: true

module A2A
  module Models
    # Represents a structured data part in a message or artifact
    # Used for forms and other structured JSON data
    class DataPart < Part
      attr_reader :data

      def initialize(data:, metadata: nil)
        super(metadata: metadata)
        @data = data
      end

      def type
        'data'
      end

      def to_h
        super.merge(data: data)
      end

      def self.from_hash(hash)
        new(
          data: hash[:data] || hash['data'],
          metadata: hash[:metadata] || hash['metadata']
        )
      end
    end
  end
end
