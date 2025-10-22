# frozen_string_literal: true

require "test_helper"

class FilePartTest < Minitest::Test
  describe "initialization" do
    def test_creates_file_part_with_file_content_object
      file_content = A2A::Models::FileContent.new(
        name: "test.txt",
        mime_type: "text/plain",
        bytes: "SGVsbG8="
      )
      part = A2A::Models::FilePart.new(file: file_content)

      assert_equal file_content, part.file
      assert_nil part.metadata
    end

    def test_creates_file_part_with_file_hash
      file_hash = {
        name: "document.pdf",
        mime_type: "application/pdf",
        bytes: "cGRmZGF0YQ=="
      }
      part = A2A::Models::FilePart.new(file: file_hash)

      assert_kind_of A2A::Models::FileContent, part.file
      assert_equal "document.pdf", part.file.name
      assert_equal "application/pdf", part.file.mime_type
      assert_equal "cGRmZGF0YQ==", part.file.bytes
    end

    def test_creates_file_part_with_metadata
      file_content = A2A::Models::FileContent.new(bytes: "data")
      metadata = { "version" => "1.0" }
      part = A2A::Models::FilePart.new(file: file_content, metadata: metadata)

      assert_equal metadata, part.metadata
    end
  end

  describe "type" do
    def test_type_returns_file
      file_content = A2A::Models::FileContent.new(bytes: "data")
      part = A2A::Models::FilePart.new(file: file_content)

      assert_equal "file", part.type
    end
  end

  describe "to_h" do
    def test_to_h_with_bytes
      file_content = A2A::Models::FileContent.new(
        name: "report.pdf",
        mime_type: "application/pdf",
        bytes: "base64data"
      )
      part = A2A::Models::FilePart.new(file: file_content)
      hash = part.to_h

      assert_equal "file", hash[:type]
      assert_kind_of Hash, hash[:file]
      assert_equal "report.pdf", hash[:file][:name]
      assert_equal "application/pdf", hash[:file][:mimeType]
      assert_equal "base64data", hash[:file][:bytes]
    end

    def test_to_h_with_uri
      file_content = A2A::Models::FileContent.new(
        name: "image.png",
        uri: "https://example.com/image.png"
      )
      part = A2A::Models::FilePart.new(file: file_content)
      hash = part.to_h

      assert_equal "file", hash[:type]
      assert_equal "image.png", hash[:file][:name]
      assert_equal "https://example.com/image.png", hash[:file][:uri]
      refute hash[:file].key?(:bytes)
    end

    def test_to_h_with_metadata
      file_content = A2A::Models::FileContent.new(bytes: "data")
      metadata = { "source" => "upload" }
      part = A2A::Models::FilePart.new(file: file_content, metadata: metadata)
      hash = part.to_h

      assert_equal "file", hash[:type]
      assert_equal metadata, hash[:metadata]
    end

    def test_to_h_excludes_nil_metadata
      file_content = A2A::Models::FileContent.new(bytes: "data")
      part = A2A::Models::FilePart.new(file: file_content)
      hash = part.to_h

      refute hash.key?(:metadata)
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        file: {
          name: "test.txt",
          mimeType: "text/plain",
          bytes: "dGVzdA=="
        },
        metadata: { "key" => "value" }
      }
      part = A2A::Models::FilePart.from_hash(hash)

      assert_kind_of A2A::Models::FileContent, part.file
      assert_equal "test.txt", part.file.name
      assert_equal "text/plain", part.file.mime_type
      assert_equal "dGVzdA==", part.file.bytes
      assert_equal({ "key" => "value" }, part.metadata)
    end

    def test_from_hash_with_string_keys
      hash = {
        "file" => {
          "name" => "data.json",
          "mimeType" => "application/json",
          "uri" => "https://api.example.com/data.json"
        }
      }
      part = A2A::Models::FilePart.from_hash(hash)

      assert_equal "data.json", part.file.name
      assert_equal "application/json", part.file.mime_type
      assert_equal "https://api.example.com/data.json", part.file.uri
    end

    def test_from_hash_without_metadata
      hash = {
        file: {
          bytes: "minimal"
        }
      }
      part = A2A::Models::FilePart.from_hash(hash)

      assert_nil part.metadata
      assert_equal "minimal", part.file.bytes
    end
  end

  describe "inheritance" do
    def test_file_part_inherits_from_part
      file_content = A2A::Models::FileContent.new(bytes: "data")
      part = A2A::Models::FilePart.new(file: file_content)

      assert_kind_of A2A::Models::Part, part
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_bytes
      original = A2A::Models::FilePart.new(
        file: A2A::Models::FileContent.new(
          name: "attachment.pdf",
          mime_type: "application/pdf",
          bytes: "cGRmY29udGVudA=="
        ),
        metadata: { "uploaded_by" => "user123" }
      )

      hash = original.to_h
      restored = A2A::Models::FilePart.from_hash(hash)

      assert_equal original.type, restored.type
      assert_equal original.file.name, restored.file.name
      assert_equal original.file.mime_type, restored.file.mime_type
      assert_equal original.file.bytes, restored.file.bytes
      assert_equal original.metadata, restored.metadata
    end

    def test_round_trip_with_uri
      original = A2A::Models::FilePart.new(
        file: {
          name: "video.mp4",
          mime_type: "video/mp4",
          uri: "https://cdn.example.com/videos/video.mp4"
        }
      )

      hash = original.to_h
      restored = A2A::Models::FilePart.from_hash(hash)

      assert_equal original.file.name, restored.file.name
      assert_equal original.file.uri, restored.file.uri
    end
  end

  describe "edge cases" do
    def test_handles_file_with_only_bytes
      part = A2A::Models::FilePart.new(file: { bytes: "minimalbytes" })

      assert_nil part.file.name
      assert_nil part.file.mime_type
      assert_equal "minimalbytes", part.file.bytes
    end

    def test_handles_file_with_only_uri
      part = A2A::Models::FilePart.new(file: { uri: "https://example.com/file" })

      assert_nil part.file.name
      assert_equal "https://example.com/file", part.file.uri
    end

    def test_handles_complex_metadata
      metadata = {
        "nested" => {
          "deeply" => {
            "nested" => "value"
          }
        },
        "array" => [1, 2, 3]
      }
      file_content = A2A::Models::FileContent.new(bytes: "data")
      part = A2A::Models::FilePart.new(file: file_content, metadata: metadata)

      assert_equal metadata, part.metadata
    end

    def test_validates_file_content_initialization
      error = assert_raises(ArgumentError) do
        A2A::Models::FilePart.new(file: { name: "test.txt" })
      end

      assert_match(/Either bytes or uri must be provided/, error.message)
    end
  end
end
