# frozen_string_literal: true

require "test_helper"

class DataPartTest < Minitest::Test
  describe "initialization" do
    def test_creates_data_part_with_hash_data
      data = { "name" => "John", "age" => 30 }
      part = A2A::Models::DataPart.new(data: data)

      assert_equal data, part.data
      assert_nil part.metadata
    end

    def test_creates_data_part_with_array_data
      data = [1, 2, 3, 4, 5]
      part = A2A::Models::DataPart.new(data: data)

      assert_equal data, part.data
    end

    def test_creates_data_part_with_metadata
      data = { "key" => "value" }
      metadata = { "schema_version" => "2.0" }
      part = A2A::Models::DataPart.new(data: data, metadata: metadata)

      assert_equal data, part.data
      assert_equal metadata, part.metadata
    end

    def test_creates_data_part_without_metadata
      data = { "test" => true }
      part = A2A::Models::DataPart.new(data: data)

      assert_nil part.metadata
    end
  end

  describe "type" do
    def test_type_returns_data
      part = A2A::Models::DataPart.new(data: {})
      assert_equal "data", part.type
    end
  end

  describe "to_h" do
    def test_to_h_with_hash_data
      data = { "field1" => "value1", "field2" => 123 }
      part = A2A::Models::DataPart.new(data: data)
      hash = part.to_h

      assert_equal "data", hash[:type]
      assert_equal data, hash[:data]
      refute hash.key?(:metadata)
    end

    def test_to_h_with_array_data
      data = ["item1", "item2", "item3"]
      part = A2A::Models::DataPart.new(data: data)
      hash = part.to_h

      assert_equal "data", hash[:type]
      assert_equal data, hash[:data]
    end

    def test_to_h_with_metadata
      data = { "structured" => "content" }
      metadata = { "format" => "json-schema" }
      part = A2A::Models::DataPart.new(data: data, metadata: metadata)
      hash = part.to_h

      assert_equal "data", hash[:type]
      assert_equal data, hash[:data]
      assert_equal metadata, hash[:metadata]
    end

    def test_to_h_excludes_nil_metadata
      part = A2A::Models::DataPart.new(data: { "key" => "value" })
      hash = part.to_h

      refute hash.key?(:metadata)
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        data: { "user_id" => 123, "username" => "test" },
        metadata: { "version" => "1.0" }
      }
      part = A2A::Models::DataPart.from_hash(hash)

      assert_equal({ "user_id" => 123, "username" => "test" }, part.data)
      assert_equal({ "version" => "1.0" }, part.metadata)
    end

    def test_from_hash_with_string_keys
      hash = {
        "data" => { "count" => 42 },
        "metadata" => { "source" => "api" }
      }
      part = A2A::Models::DataPart.from_hash(hash)

      assert_equal({ "count" => 42 }, part.data)
      assert_equal({ "source" => "api" }, part.metadata)
    end

    def test_from_hash_without_metadata
      hash = { data: { "simple" => "data" } }
      part = A2A::Models::DataPart.from_hash(hash)

      assert_equal({ "simple" => "data" }, part.data)
      assert_nil part.metadata
    end

    def test_from_hash_prefers_symbol_keys
      hash = {
        data: { "symbol" => "value" },
        "data" => { "string" => "value" }
      }
      part = A2A::Models::DataPart.from_hash(hash)

      assert_equal({ "symbol" => "value" }, part.data)
    end
  end

  describe "inheritance" do
    def test_data_part_inherits_from_part
      part = A2A::Models::DataPart.new(data: {})
      assert_kind_of A2A::Models::Part, part
    end
  end

  describe "edge cases" do
    def test_handles_empty_hash
      part = A2A::Models::DataPart.new(data: {})
      assert_equal({}, part.data)
    end

    def test_handles_empty_array
      part = A2A::Models::DataPart.new(data: [])
      assert_equal [], part.data
    end

    def test_handles_nested_structures
      data = {
        "user" => {
          "profile" => {
            "name" => "John",
            "contacts" => ["email@test.com", "phone"]
          }
        },
        "settings" => {
          "notifications" => true
        }
      }
      part = A2A::Models::DataPart.new(data: data)

      assert_equal data, part.data
    end

    def test_handles_mixed_type_array
      data = [1, "two", { "three" => 3 }, [4, 5], true, nil]
      part = A2A::Models::DataPart.new(data: data)

      assert_equal data, part.data
    end

    def test_handles_string_data
      data = "plain string data"
      part = A2A::Models::DataPart.new(data: data)

      assert_equal data, part.data
    end

    def test_handles_numeric_data
      part = A2A::Models::DataPart.new(data: 12345)
      assert_equal 12345, part.data
    end

    def test_handles_boolean_data
      part = A2A::Models::DataPart.new(data: true)
      assert_equal true, part.data
    end

    def test_handles_nil_data
      part = A2A::Models::DataPart.new(data: nil)
      assert_nil part.data
    end

    def test_handles_complex_metadata
      data = { "key" => "value" }
      metadata = {
        "schema" => {
          "type" => "object",
          "properties" => {
            "key" => { "type" => "string" }
          }
        },
        "validation" => ["required"]
      }
      part = A2A::Models::DataPart.new(data: data, metadata: metadata)

      assert_equal metadata, part.metadata
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_complex_data
      original = A2A::Models::DataPart.new(
        data: {
          "form_data" => {
            "fields" => [
              { "name" => "username", "type" => "text" },
              { "name" => "password", "type" => "password" }
            ]
          }
        },
        metadata: { "form_version" => "2.0" }
      )

      hash = original.to_h
      restored = A2A::Models::DataPart.from_hash(hash)

      assert_equal original.type, restored.type
      assert_equal original.data, restored.data
      assert_equal original.metadata, restored.metadata
    end

    def test_round_trip_with_array_data
      original = A2A::Models::DataPart.new(
        data: [
          { "id" => 1, "name" => "First" },
          { "id" => 2, "name" => "Second" }
        ]
      )

      hash = original.to_h
      restored = A2A::Models::DataPart.from_hash(hash)

      assert_equal original.data, restored.data
    end
  end

  describe "use cases" do
    def test_represents_form_data
      form_data = {
        "name" => "John Doe",
        "email" => "john@example.com",
        "preferences" => {
          "newsletter" => true,
          "notifications" => false
        }
      }
      part = A2A::Models::DataPart.new(data: form_data)

      assert_equal form_data, part.data
    end

    def test_represents_json_schema
      schema = {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" },
          "age" => { "type" => "integer", "minimum" => 0 }
        },
        "required" => ["name"]
      }
      part = A2A::Models::DataPart.new(data: schema)

      assert_equal schema, part.data
    end
  end
end
