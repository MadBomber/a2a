# frozen_string_literal: true

require "test_helper"

class TextPartTest < Minitest::Test
  describe "initialization" do
    def test_creates_text_part_with_text
      part = A2A::Models::TextPart.new(text: "Hello, world!")
      assert_equal "Hello, world!", part.text
    end

    def test_creates_text_part_with_metadata
      metadata = { "key" => "value" }
      part = A2A::Models::TextPart.new(text: "Test", metadata: metadata)
      assert_equal metadata, part.metadata
    end

    def test_creates_text_part_without_metadata
      part = A2A::Models::TextPart.new(text: "Test")
      assert_nil part.metadata
    end
  end

  describe "type" do
    def test_type_returns_text
      part = A2A::Models::TextPart.new(text: "Test")
      assert_equal "text", part.type
    end
  end

  describe "to_h" do
    def test_to_h_with_text_only
      part = A2A::Models::TextPart.new(text: "Hello")
      hash = part.to_h

      assert_equal "text", hash[:type]
      assert_equal "Hello", hash[:text]
      refute hash.key?(:metadata)
    end

    def test_to_h_with_metadata
      metadata = { "author" => "test" }
      part = A2A::Models::TextPart.new(text: "Hello", metadata: metadata)
      hash = part.to_h

      assert_equal "text", hash[:type]
      assert_equal "Hello", hash[:text]
      assert_equal metadata, hash[:metadata]
    end

    def test_to_h_excludes_nil_metadata
      part = A2A::Models::TextPart.new(text: "Hello", metadata: nil)
      hash = part.to_h

      refute hash.key?(:metadata)
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = { text: "Test content", metadata: { "key" => "value" } }
      part = A2A::Models::TextPart.from_hash(hash)

      assert_equal "Test content", part.text
      assert_equal({ "key" => "value" }, part.metadata)
    end

    def test_from_hash_with_string_keys
      hash = { "text" => "Test content", "metadata" => { "key" => "value" } }
      part = A2A::Models::TextPart.from_hash(hash)

      assert_equal "Test content", part.text
      assert_equal({ "key" => "value" }, part.metadata)
    end

    def test_from_hash_without_metadata
      hash = { text: "Test content" }
      part = A2A::Models::TextPart.from_hash(hash)

      assert_equal "Test content", part.text
      assert_nil part.metadata
    end

    def test_from_hash_prefers_symbol_keys
      hash = { text: "symbol", "text" => "string" }
      part = A2A::Models::TextPart.from_hash(hash)

      assert_equal "symbol", part.text
    end
  end

  describe "inheritance" do
    def test_text_part_inherits_from_part
      part = A2A::Models::TextPart.new(text: "Test")
      assert_kind_of A2A::Models::Part, part
    end
  end

  describe "edge cases" do
    def test_handles_empty_text
      part = A2A::Models::TextPart.new(text: "")
      assert_equal "", part.text
    end

    def test_handles_multiline_text
      multiline = "Line 1\nLine 2\nLine 3"
      part = A2A::Models::TextPart.new(text: multiline)
      assert_equal multiline, part.text
    end

    def test_handles_unicode_text
      unicode = "Hello 世界 🌍"
      part = A2A::Models::TextPart.new(text: unicode)
      assert_equal unicode, part.text
    end

    def test_handles_complex_metadata
      metadata = {
        "nested" => {
          "key" => "value"
        },
        "array" => [1, 2, 3]
      }
      part = A2A::Models::TextPart.new(text: "Test", metadata: metadata)
      assert_equal metadata, part.metadata
    end
  end

  describe "serialization round-trip" do
    def test_to_h_and_from_hash_round_trip
      original = A2A::Models::TextPart.new(
        text: "Round trip test",
        metadata: { "version" => "1.0" }
      )

      hash = original.to_h
      restored = A2A::Models::TextPart.from_hash(hash)

      assert_equal original.text, restored.text
      assert_equal original.metadata, restored.metadata
      assert_equal original.type, restored.type
    end
  end
end
