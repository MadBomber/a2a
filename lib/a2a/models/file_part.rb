# frozen_string_literal: true

require_relative 'file_content'

module A2A
  module Models
    # Represents a file part in a message or artifact
    class FilePart < Part
      attr_reader :file

      def initialize(file:, metadata: nil)
        super(metadata: metadata)
        @file = file.is_a?(FileContent) ? file : FileContent.new(**file)
      end

      def type
        'file'
      end

      def to_h
        super.merge(file: file.to_h)
      end

      def self.from_hash(hash)
        new(
          file: FileContent.from_hash(hash[:file] || hash['file']),
          metadata: hash[:metadata] || hash['metadata']
        )
      end
    end
  end
end
