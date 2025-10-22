# frozen_string_literal: true

module A2A
  module Models
    # Base class for message/artifact parts
    # Parts can be TextPart, FilePart, or DataPart
    class Part
      attr_reader :metadata

      def initialize(metadata: nil)
        @metadata = metadata
      end

      def type
        raise NotImplementedError, "Subclasses must implement #type"
      end

      def to_h
        {
          type: type,
          metadata: metadata
        }.compact
      end

      def to_json(*args)
        to_h.to_json(*args)
      end

      # Factory method to create the appropriate Part subclass from a hash
      def self.from_hash(hash)
        case hash[:type] || hash['type']
        when 'text'
          TextPart.from_hash(hash)
        when 'file'
          FilePart.from_hash(hash)
        when 'data'
          DataPart.from_hash(hash)
        else
          raise ArgumentError, "Unknown part type: #{hash[:type] || hash['type']}"
        end
      end
    end
  end
end
