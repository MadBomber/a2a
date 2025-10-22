# frozen_string_literal: true

require "test_helper"

class MessageTest < Minitest::Test
  describe "initialization" do
    def test_creates_message_with_valid_role_and_parts
      text_part = A2A::Models::TextPart.new(text: "Hello")
      message = A2A::Models::Message.new(role: "user", parts: [text_part])

      assert_equal "user", message.role
      assert_equal 1, message.parts.length
      assert_equal text_part, message.parts.first
    end

    def test_creates_message_with_agent_role
      text_part = A2A::Models::TextPart.new(text: "Response")
      message = A2A::Models::Message.new(role: "agent", parts: [text_part])

      assert_equal "agent", message.role
    end

    def test_creates_message_with_metadata
      text_part = A2A::Models::TextPart.new(text: "Test")
      metadata = { "timestamp" => "2025-10-21T12:00:00Z" }
      message = A2A::Models::Message.new(
        role: "user",
        parts: [text_part],
        metadata: metadata
      )

      assert_equal metadata, message.metadata
    end

    def test_raises_error_for_invalid_role
      text_part = A2A::Models::TextPart.new(text: "Test")

      error = assert_raises(ArgumentError) do
        A2A::Models::Message.new(role: "invalid", parts: [text_part])
      end

      assert_match(/Invalid role/, error.message)
      assert_match(/Must be one of/, error.message)
    end

    def test_normalizes_part_hashes_to_part_objects
      parts_hash = [
        { type: "text", text: "Hello" },
        { type: "data", data: { "key" => "value" } }
      ]
      message = A2A::Models::Message.new(role: "user", parts: parts_hash)

      assert_equal 2, message.parts.length
      assert_kind_of A2A::Models::TextPart, message.parts[0]
      assert_kind_of A2A::Models::DataPart, message.parts[1]
    end
  end

  describe "ROLES constant" do
    def test_roles_constant_includes_user_and_agent
      assert_equal %w[user agent], A2A::Models::Message::ROLES
    end

    def test_roles_constant_is_frozen
      assert A2A::Models::Message::ROLES.frozen?
    end
  end

  describe "to_h" do
    def test_to_h_with_single_text_part
      text_part = A2A::Models::TextPart.new(text: "Hello")
      message = A2A::Models::Message.new(role: "user", parts: [text_part])
      hash = message.to_h

      assert_equal "user", hash[:role]
      assert_equal 1, hash[:parts].length
      assert_equal "text", hash[:parts][0][:type]
      assert_equal "Hello", hash[:parts][0][:text]
    end

    def test_to_h_with_multiple_parts
      parts = [
        A2A::Models::TextPart.new(text: "Question"),
        A2A::Models::DataPart.new(data: { "context" => "test" })
      ]
      message = A2A::Models::Message.new(role: "user", parts: parts)
      hash = message.to_h

      assert_equal 2, hash[:parts].length
      assert_equal "text", hash[:parts][0][:type]
      assert_equal "data", hash[:parts][1][:type]
    end

    def test_to_h_with_metadata
      text_part = A2A::Models::TextPart.new(text: "Test")
      metadata = { "session_id" => "123" }
      message = A2A::Models::Message.new(
        role: "agent",
        parts: [text_part],
        metadata: metadata
      )
      hash = message.to_h

      assert_equal "agent", hash[:role]
      assert_equal metadata, hash[:metadata]
    end

    def test_to_h_excludes_nil_metadata
      text_part = A2A::Models::TextPart.new(text: "Test")
      message = A2A::Models::Message.new(role: "user", parts: [text_part])
      hash = message.to_h

      refute hash.key?(:metadata)
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        role: "user",
        parts: [
          { type: "text", text: "Hello" }
        ],
        metadata: { "key" => "value" }
      }
      message = A2A::Models::Message.from_hash(hash)

      assert_equal "user", message.role
      assert_equal 1, message.parts.length
      assert_kind_of A2A::Models::TextPart, message.parts.first
      assert_equal "Hello", message.parts.first.text
      assert_equal({ "key" => "value" }, message.metadata)
    end

    def test_from_hash_with_string_keys
      hash = {
        "role" => "agent",
        "parts" => [
          { "type" => "text", "text" => "Response" }
        ]
      }
      message = A2A::Models::Message.from_hash(hash)

      assert_equal "agent", message.role
      assert_equal 1, message.parts.length
      assert_equal "Response", message.parts.first.text
    end

    def test_from_hash_with_multiple_part_types
      hash = {
        role: "user",
        parts: [
          { type: "text", text: "Question" },
          { type: "file", file: { bytes: "data" } },
          { type: "data", data: { "answer" => 42 } }
        ]
      }
      message = A2A::Models::Message.from_hash(hash)

      assert_equal 3, message.parts.length
      assert_kind_of A2A::Models::TextPart, message.parts[0]
      assert_kind_of A2A::Models::FilePart, message.parts[1]
      assert_kind_of A2A::Models::DataPart, message.parts[2]
    end
  end

  describe "text factory method" do
    def test_text_creates_message_with_user_role
      message = A2A::Models::Message.text(role: "user", text: "Hello")

      assert_equal "user", message.role
      assert_equal 1, message.parts.length
      assert_kind_of A2A::Models::TextPart, message.parts.first
      assert_equal "Hello", message.parts.first.text
    end

    def test_text_creates_message_with_agent_role
      message = A2A::Models::Message.text(role: "agent", text: "Response")

      assert_equal "agent", message.role
      assert_equal "Response", message.parts.first.text
    end

    def test_text_with_metadata
      metadata = { "timestamp" => "2025-10-21" }
      message = A2A::Models::Message.text(
        role: "user",
        text: "Test",
        metadata: metadata
      )

      assert_equal metadata, message.metadata
    end

    def test_text_validates_role
      error = assert_raises(ArgumentError) do
        A2A::Models::Message.text(role: "invalid", text: "Test")
      end

      assert_match(/Invalid role/, error.message)
    end

    def test_text_with_empty_string
      message = A2A::Models::Message.text(role: "user", text: "")

      assert_equal "", message.parts.first.text
    end

    def test_text_with_multiline_content
      multiline = "Line 1\nLine 2\nLine 3"
      message = A2A::Models::Message.text(role: "user", text: multiline)

      assert_equal multiline, message.parts.first.text
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_single_text_part
      original = A2A::Models::Message.text(
        role: "user",
        text: "Test message",
        metadata: { "version" => "1.0" }
      )

      hash = original.to_h
      restored = A2A::Models::Message.from_hash(hash)

      assert_equal original.role, restored.role
      assert_equal original.parts.length, restored.parts.length
      assert_equal original.parts.first.text, restored.parts.first.text
      assert_equal original.metadata, restored.metadata
    end

    def test_round_trip_with_multiple_parts
      original = A2A::Models::Message.new(
        role: "agent",
        parts: [
          A2A::Models::TextPart.new(text: "Here's your data:"),
          A2A::Models::DataPart.new(data: { "result" => 42 }),
          A2A::Models::FilePart.new(file: { bytes: "filedata" })
        ]
      )

      hash = original.to_h
      restored = A2A::Models::Message.from_hash(hash)

      assert_equal original.role, restored.role
      assert_equal original.parts.length, restored.parts.length
      assert_equal original.parts[0].text, restored.parts[0].text
      assert_equal original.parts[1].data, restored.parts[1].data
    end
  end

  describe "edge cases" do
    def test_handles_empty_parts_array
      A2A::Models::TextPart.new(text: "test")
      message = A2A::Models::Message.new(role: "user", parts: [])

      assert_equal 0, message.parts.length
    end

    def test_handles_parts_with_metadata
      parts = [
        A2A::Models::TextPart.new(text: "Hello", metadata: { "lang" => "en" })
      ]
      message = A2A::Models::Message.new(role: "user", parts: parts)
      hash = message.to_h

      assert_equal({ "lang" => "en" }, hash[:parts][0][:metadata])
    end

    def test_mixed_part_objects_and_hashes
      parts = [
        A2A::Models::TextPart.new(text: "Object part"),
        { type: "text", text: "Hash part" }
      ]
      message = A2A::Models::Message.new(role: "user", parts: parts)

      assert_equal 2, message.parts.length
      assert_kind_of A2A::Models::TextPart, message.parts[0]
      assert_kind_of A2A::Models::TextPart, message.parts[1]
    end
  end

  describe "use cases" do
    def test_represents_user_text_query
      message = A2A::Models::Message.text(
        role: "user",
        text: "What is the weather like today?"
      )

      assert_equal "user", message.role
      assert_equal "What is the weather like today?", message.parts.first.text
    end

    def test_represents_agent_response
      message = A2A::Models::Message.text(
        role: "agent",
        text: "The weather is sunny with a high of 75°F."
      )

      assert_equal "agent", message.role
      assert_kind_of A2A::Models::TextPart, message.parts.first
    end

    def test_represents_multimodal_message
      message = A2A::Models::Message.new(
        role: "user",
        parts: [
          A2A::Models::TextPart.new(text: "Analyze this image:"),
          A2A::Models::FilePart.new(
            file: {
              name: "photo.jpg",
              mime_type: "image/jpeg",
              uri: "https://example.com/photo.jpg"
            }
          )
        ]
      )

      assert_equal 2, message.parts.length
      assert_kind_of A2A::Models::TextPart, message.parts[0]
      assert_kind_of A2A::Models::FilePart, message.parts[1]
    end
  end
end
