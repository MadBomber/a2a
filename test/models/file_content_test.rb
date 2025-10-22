# frozen_string_literal: true

require "test_helper"

class FileContentTest < Minitest::Test
  describe "initialization" do
    def test_creates_file_content_with_bytes
      content = A2A::Models::FileContent.new(
        name: "test.txt",
        mime_type: "text/plain",
        bytes: "SGVsbG8gV29ybGQ="
      )

      assert_equal "test.txt", content.name
      assert_equal "text/plain", content.mime_type
      assert_equal "SGVsbG8gV29ybGQ=", content.bytes
      assert_nil content.uri
    end

    def test_creates_file_content_with_uri
      content = A2A::Models::FileContent.new(
        name: "test.txt",
        mime_type: "text/plain",
        uri: "https://example.com/file.txt"
      )

      assert_equal "test.txt", content.name
      assert_equal "text/plain", content.mime_type
      assert_nil content.bytes
      assert_equal "https://example.com/file.txt", content.uri
    end

    def test_creates_file_content_with_minimal_data
      content = A2A::Models::FileContent.new(bytes: "data")

      assert_nil content.name
      assert_nil content.mime_type
      assert_equal "data", content.bytes
    end
  end

  describe "validation" do
    def test_raises_error_when_neither_bytes_nor_uri_provided
      error = assert_raises(ArgumentError) do
        A2A::Models::FileContent.new(name: "test.txt")
      end

      assert_match(/Either bytes or uri must be provided/, error.message)
    end

    def test_raises_error_when_both_bytes_and_uri_provided
      error = assert_raises(ArgumentError) do
        A2A::Models::FileContent.new(
          bytes: "SGVsbG8=",
          uri: "https://example.com/file.txt"
        )
      end

      assert_match(/Only one of bytes or uri can be provided/, error.message)
    end

    def test_accepts_nil_name_and_mime_type
      content = A2A::Models::FileContent.new(bytes: "data")

      assert_nil content.name
      assert_nil content.mime_type
    end
  end

  describe "to_h" do
    def test_to_h_with_bytes
      content = A2A::Models::FileContent.new(
        name: "file.pdf",
        mime_type: "application/pdf",
        bytes: "base64data"
      )

      hash = content.to_h

      assert_equal "file.pdf", hash[:name]
      assert_equal "application/pdf", hash[:mimeType]
      assert_equal "base64data", hash[:bytes]
      refute hash.key?(:uri)
    end

    def test_to_h_with_uri
      content = A2A::Models::FileContent.new(
        name: "image.png",
        mime_type: "image/png",
        uri: "https://example.com/image.png"
      )

      hash = content.to_h

      assert_equal "image.png", hash[:name]
      assert_equal "image/png", hash[:mimeType]
      assert_equal "https://example.com/image.png", hash[:uri]
      refute hash.key?(:bytes)
    end

    def test_to_h_excludes_nil_values
      content = A2A::Models::FileContent.new(bytes: "data")
      hash = content.to_h

      refute hash.key?(:name)
      refute hash.key?(:mimeType)
      assert_equal "data", hash[:bytes]
    end

    def test_to_h_uses_camel_case_for_mime_type
      content = A2A::Models::FileContent.new(
        mime_type: "text/plain",
        bytes: "data"
      )

      hash = content.to_h

      assert hash.key?(:mimeType)
      refute hash.key?(:mime_type)
    end
  end

  describe "from_hash" do
    def test_from_hash_with_bytes_and_symbol_keys
      hash = {
        name: "test.txt",
        mimeType: "text/plain",
        bytes: "SGVsbG8="
      }

      content = A2A::Models::FileContent.from_hash(hash)

      assert_equal "test.txt", content.name
      assert_equal "text/plain", content.mime_type
      assert_equal "SGVsbG8=", content.bytes
      assert_nil content.uri
    end

    def test_from_hash_with_uri_and_string_keys
      hash = {
        "name" => "image.jpg",
        "mimeType" => "image/jpeg",
        "uri" => "https://example.com/image.jpg"
      }

      content = A2A::Models::FileContent.from_hash(hash)

      assert_equal "image.jpg", content.name
      assert_equal "image/jpeg", content.mime_type
      assert_equal "https://example.com/image.jpg", content.uri
      assert_nil content.bytes
    end

    def test_from_hash_handles_mime_type_variations
      hash1 = { mimeType: "text/plain", bytes: "data" }
      content1 = A2A::Models::FileContent.from_hash(hash1)
      assert_equal "text/plain", content1.mime_type

      hash2 = { mime_type: "text/html", bytes: "data" }
      content2 = A2A::Models::FileContent.from_hash(hash2)
      assert_equal "text/html", content2.mime_type
    end

    def test_from_hash_with_minimal_data
      hash = { bytes: "minimal" }
      content = A2A::Models::FileContent.from_hash(hash)

      assert_nil content.name
      assert_nil content.mime_type
      assert_equal "minimal", content.bytes
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_bytes
      original = A2A::Models::FileContent.new(
        name: "document.pdf",
        mime_type: "application/pdf",
        bytes: "base64encodedcontent"
      )

      hash = original.to_h
      restored = A2A::Models::FileContent.from_hash(hash)

      assert_equal original.name, restored.name
      assert_equal original.mime_type, restored.mime_type
      assert_equal original.bytes, restored.bytes
      assert_nil restored.uri
    end

    def test_round_trip_with_uri
      original = A2A::Models::FileContent.new(
        name: "photo.jpg",
        mime_type: "image/jpeg",
        uri: "https://cdn.example.com/photos/photo.jpg"
      )

      hash = original.to_h
      restored = A2A::Models::FileContent.from_hash(hash)

      assert_equal original.name, restored.name
      assert_equal original.mime_type, restored.mime_type
      assert_equal original.uri, restored.uri
      assert_nil restored.bytes
    end
  end

  describe "edge cases" do
    def test_handles_empty_byte_string
      content = A2A::Models::FileContent.new(bytes: "")
      assert_equal "", content.bytes
    end

    def test_handles_various_mime_types
      mime_types = [
        "text/plain",
        "application/json",
        "image/png",
        "video/mp4",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      ]

      mime_types.each do |mime_type|
        content = A2A::Models::FileContent.new(mime_type: mime_type, bytes: "data")
        assert_equal mime_type, content.mime_type
      end
    end

    def test_handles_long_file_names
      long_name = "#{"a" * 255}.txt"
      content = A2A::Models::FileContent.new(name: long_name, bytes: "data")
      assert_equal long_name, content.name
    end

    def test_handles_special_characters_in_uri
      uri = "https://example.com/files/test%20file%20(1).txt?version=2"
      content = A2A::Models::FileContent.new(uri: uri)
      assert_equal uri, content.uri
    end
  end
end
