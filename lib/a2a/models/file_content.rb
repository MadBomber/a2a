# frozen_string_literal: true

module A2A
  module Models
    # Represents the content of a file, either as base64 encoded bytes or a URI
    # Ensures that either 'bytes' or 'uri' is provided, but not both
    class FileContent
      attr_reader :name, :mime_type, :bytes, :uri

      def initialize(name: nil, mime_type: nil, bytes: nil, uri: nil)
        validate_content(bytes, uri)

        @name = name
        @mime_type = mime_type
        @bytes = bytes
        @uri = uri
      end

      def to_h
        {
          name: name,
          mimeType: mime_type,
          bytes: bytes,
          uri: uri
        }.compact
      end

      def to_json(*)
        to_h.to_json(*)
      end

      def self.from_hash(hash)
        new(
          name: hash[:name] || hash['name'],
          mime_type: hash[:mimeType] || hash['mimeType'] || hash[:mime_type],
          bytes: hash[:bytes] || hash['bytes'],
          uri: hash[:uri] || hash['uri']
        )
      end

      private

      def validate_content(bytes, uri)
        raise ArgumentError, "Either bytes or uri must be provided" if bytes.nil? && uri.nil?

        return unless bytes && uri

        raise ArgumentError, "Only one of bytes or uri can be provided, not both"
      end
    end
  end
end
