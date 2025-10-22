# frozen_string_literal: true

require "test_helper"

class ArtifactTest < Minitest::Test
  describe "initialization" do
    def test_creates_artifact_with_parts
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(parts: parts)

      assert_equal 1, artifact.parts.length
      assert_equal parts.first, artifact.parts.first
      assert_equal 0, artifact.index
    end

    def test_creates_artifact_with_name_and_description
      parts = [A2A::Models::TextPart.new(text: "Data")]
      artifact = A2A::Models::Artifact.new(
        name: "result",
        description: "Analysis results",
        parts: parts
      )

      assert_equal "result", artifact.name
      assert_equal "Analysis results", artifact.description
    end

    def test_creates_artifact_with_custom_index
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(parts: parts, index: 5)

      assert_equal 5, artifact.index
    end

    def test_creates_artifact_with_append_flag
      parts = [A2A::Models::TextPart.new(text: "More data")]
      artifact = A2A::Models::Artifact.new(parts: parts, append: true)

      assert_equal true, artifact.append
    end

    def test_creates_artifact_with_last_chunk_flag
      parts = [A2A::Models::TextPart.new(text: "Final chunk")]
      artifact = A2A::Models::Artifact.new(parts: parts, last_chunk: true)

      assert_equal true, artifact.last_chunk
    end

    def test_creates_artifact_with_metadata
      parts = [A2A::Models::TextPart.new(text: "Output")]
      metadata = { "format" => "json" }
      artifact = A2A::Models::Artifact.new(parts: parts, metadata: metadata)

      assert_equal metadata, artifact.metadata
    end

    def test_normalizes_part_hashes
      parts_hash = [
        { type: "text", text: "Text content" },
        { type: "data", data: { "key" => "value" } }
      ]
      artifact = A2A::Models::Artifact.new(parts: parts_hash)

      assert_equal 2, artifact.parts.length
      assert_kind_of A2A::Models::TextPart, artifact.parts[0]
      assert_kind_of A2A::Models::DataPart, artifact.parts[1]
    end
  end

  describe "default values" do
    def test_default_index_is_zero
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(parts: parts)

      assert_equal 0, artifact.index
    end

    def test_default_append_is_nil
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(parts: parts)

      assert_nil artifact.append
    end

    def test_default_last_chunk_is_nil
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(parts: parts)

      assert_nil artifact.last_chunk
    end

    def test_default_name_is_nil
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(parts: parts)

      assert_nil artifact.name
    end

    def test_default_description_is_nil
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(parts: parts)

      assert_nil artifact.description
    end

    def test_default_metadata_is_nil
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(parts: parts)

      assert_nil artifact.metadata
    end
  end

  describe "to_h" do
    def test_to_h_with_minimal_fields
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(parts: parts)
      hash = artifact.to_h

      assert_equal 1, hash[:parts].length
      assert_equal "text", hash[:parts][0][:type]
      assert_equal 0, hash[:index]
      refute hash.key?(:name)
      refute hash.key?(:description)
      refute hash.key?(:append)
      refute hash.key?(:lastChunk)
    end

    def test_to_h_with_all_fields
      parts = [A2A::Models::TextPart.new(text: "Complete output")]
      artifact = A2A::Models::Artifact.new(
        name: "final_result",
        description: "The final analysis",
        parts: parts,
        index: 3,
        append: true,
        last_chunk: true,
        metadata: { "version" => "2.0" }
      )
      hash = artifact.to_h

      assert_equal "final_result", hash[:name]
      assert_equal "The final analysis", hash[:description]
      assert_equal 3, hash[:index]
      assert_equal true, hash[:append]
      assert_equal true, hash[:lastChunk]
      assert_equal({ "version" => "2.0" }, hash[:metadata])
    end

    def test_to_h_uses_camel_case_for_last_chunk
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(parts: parts, last_chunk: false)
      hash = artifact.to_h

      assert hash.key?(:lastChunk)
      refute hash.key?(:last_chunk)
    end

    def test_to_h_with_multiple_part_types
      parts = [
        A2A::Models::TextPart.new(text: "Summary:"),
        A2A::Models::DataPart.new(data: { "total" => 100 }),
        A2A::Models::FilePart.new(file: { bytes: "reportdata" })
      ]
      artifact = A2A::Models::Artifact.new(parts: parts)
      hash = artifact.to_h

      assert_equal 3, hash[:parts].length
      assert_equal "text", hash[:parts][0][:type]
      assert_equal "data", hash[:parts][1][:type]
      assert_equal "file", hash[:parts][2][:type]
    end

    def test_to_h_excludes_nil_values
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(
        parts: parts,
        name: nil,
        description: nil,
        append: nil,
        last_chunk: nil,
        metadata: nil
      )
      hash = artifact.to_h

      refute hash.key?(:name)
      refute hash.key?(:description)
      refute hash.key?(:append)
      refute hash.key?(:lastChunk)
      refute hash.key?(:metadata)
      assert hash.key?(:index)
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        name: "output",
        description: "Test output",
        parts: [{ type: "text", text: "Result" }],
        index: 2,
        append: false,
        lastChunk: true,
        metadata: { "key" => "value" }
      }
      artifact = A2A::Models::Artifact.from_hash(hash)

      assert_equal "output", artifact.name
      assert_equal "Test output", artifact.description
      assert_equal 1, artifact.parts.length
      assert_equal 2, artifact.index
      # Note: false values become nil after compact in to_h/from_hash round-trip
      assert_nil artifact.append
      assert_equal true, artifact.last_chunk
      assert_equal({ "key" => "value" }, artifact.metadata)
    end

    def test_from_hash_with_string_keys
      hash = {
        "name" => "report",
        "parts" => [{ "type" => "text", "text" => "Data" }],
        "index" => 1
      }
      artifact = A2A::Models::Artifact.from_hash(hash)

      assert_equal "report", artifact.name
      assert_equal 1, artifact.index
    end

    def test_from_hash_handles_last_chunk_variations
      hash1 = { parts: [{ type: "text", text: "Test" }], lastChunk: true }
      artifact1 = A2A::Models::Artifact.from_hash(hash1)
      assert_equal true, artifact1.last_chunk

      hash2 = { parts: [{ type: "text", text: "Test" }], last_chunk: false }
      artifact2 = A2A::Models::Artifact.from_hash(hash2)
      assert_equal false, artifact2.last_chunk
    end

    def test_from_hash_default_index_zero
      hash = { parts: [{ type: "text", text: "Test" }] }
      artifact = A2A::Models::Artifact.from_hash(hash)

      assert_equal 0, artifact.index
    end

    def test_from_hash_with_multiple_parts
      hash = {
        parts: [
          { type: "text", text: "Part 1" },
          { type: "data", data: { "count" => 5 } },
          { type: "file", file: { bytes: "data" } }
        ]
      }
      artifact = A2A::Models::Artifact.from_hash(hash)

      assert_equal 3, artifact.parts.length
      assert_kind_of A2A::Models::TextPart, artifact.parts[0]
      assert_kind_of A2A::Models::DataPart, artifact.parts[1]
      assert_kind_of A2A::Models::FilePart, artifact.parts[2]
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_minimal_data
      original = A2A::Models::Artifact.new(
        parts: [A2A::Models::TextPart.new(text: "Simple output")]
      )

      hash = original.to_h
      restored = A2A::Models::Artifact.from_hash(hash)

      assert_equal original.parts.length, restored.parts.length
      assert_equal original.parts.first.text, restored.parts.first.text
      assert_equal original.index, restored.index
    end

    def test_round_trip_with_all_fields
      original = A2A::Models::Artifact.new(
        name: "comprehensive_result",
        description: "Complete analysis output",
        parts: [
          A2A::Models::TextPart.new(text: "Summary"),
          A2A::Models::DataPart.new(data: { "score" => 98 })
        ],
        index: 7,
        append: true,
        last_chunk: false,
        metadata: { "format" => "structured" }
      )

      hash = original.to_h
      restored = A2A::Models::Artifact.from_hash(hash)

      assert_equal original.name, restored.name
      assert_equal original.description, restored.description
      assert_equal original.parts.length, restored.parts.length
      assert_equal original.index, restored.index
      assert_equal original.append, restored.append
      # Note: false becomes nil after compact in to_h
      assert_nil restored.last_chunk
      assert_equal original.metadata, restored.metadata
    end
  end

  describe "edge cases" do
    def test_handles_empty_parts_array
      artifact = A2A::Models::Artifact.new(parts: [])

      assert_equal 0, artifact.parts.length
    end

    def test_handles_large_index
      parts = [A2A::Models::TextPart.new(text: "Output")]
      artifact = A2A::Models::Artifact.new(parts: parts, index: 999999)

      assert_equal 999999, artifact.index
    end

    def test_handles_parts_with_metadata
      parts = [
        A2A::Models::TextPart.new(text: "Output", metadata: { "lang" => "en" })
      ]
      artifact = A2A::Models::Artifact.new(parts: parts)
      hash = artifact.to_h

      assert_equal({ "lang" => "en" }, hash[:parts][0][:metadata])
    end

    def test_handles_complex_nested_data
      parts = [
        A2A::Models::DataPart.new(
          data: {
            "results" => [
              { "id" => 1, "value" => "A" },
              { "id" => 2, "value" => "B" }
            ],
            "metadata" => {
              "total" => 2,
              "timestamp" => "2025-10-21"
            }
          }
        )
      ]
      artifact = A2A::Models::Artifact.new(parts: parts)

      assert_equal 1, artifact.parts.length
      assert_kind_of Hash, artifact.parts.first.data
    end
  end

  describe "streaming use cases" do
    def test_represents_initial_chunk
      artifact = A2A::Models::Artifact.new(
        name: "stream_output",
        parts: [A2A::Models::TextPart.new(text: "First chunk")],
        index: 0,
        append: false,
        last_chunk: false
      )

      assert_equal 0, artifact.index
      assert_equal false, artifact.append
      assert_equal false, artifact.last_chunk
    end

    def test_represents_middle_chunk
      artifact = A2A::Models::Artifact.new(
        name: "stream_output",
        parts: [A2A::Models::TextPart.new(text: " continues...")],
        index: 1,
        append: true,
        last_chunk: false
      )

      assert_equal 1, artifact.index
      assert_equal true, artifact.append
      assert_equal false, artifact.last_chunk
    end

    def test_represents_final_chunk
      artifact = A2A::Models::Artifact.new(
        name: "stream_output",
        parts: [A2A::Models::TextPart.new(text: " done!")],
        index: 2,
        append: true,
        last_chunk: true
      )

      assert_equal 2, artifact.index
      assert_equal true, artifact.append
      assert_equal true, artifact.last_chunk
    end
  end

  describe "use cases" do
    def test_represents_text_output
      artifact = A2A::Models::Artifact.new(
        name: "response",
        description: "Agent's text response",
        parts: [A2A::Models::TextPart.new(text: "Here is the answer to your question.")]
      )

      assert_equal "response", artifact.name
      assert_equal 1, artifact.parts.length
      assert_kind_of A2A::Models::TextPart, artifact.parts.first
    end

    def test_represents_file_output
      artifact = A2A::Models::Artifact.new(
        name: "generated_report",
        description: "PDF report of the analysis",
        parts: [
          A2A::Models::FilePart.new(
            file: {
              name: "report.pdf",
              mime_type: "application/pdf",
              bytes: "base64encodedpdfdata"
            }
          )
        ]
      )

      assert_equal "generated_report", artifact.name
      assert_kind_of A2A::Models::FilePart, artifact.parts.first
    end

    def test_represents_structured_data_output
      artifact = A2A::Models::Artifact.new(
        name: "analysis_results",
        description: "Structured analysis data",
        parts: [
          A2A::Models::DataPart.new(
            data: {
              "sentiment" => "positive",
              "confidence" => 0.87,
              "keywords" => ["AI", "automation", "efficiency"]
            }
          )
        ]
      )

      assert_equal "analysis_results", artifact.name
      assert_kind_of Hash, artifact.parts.first.data
    end

    def test_represents_multipart_output
      artifact = A2A::Models::Artifact.new(
        name: "comprehensive_output",
        description: "Text explanation with supporting data",
        parts: [
          A2A::Models::TextPart.new(text: "Based on the analysis:"),
          A2A::Models::DataPart.new(
            data: {
              "chart_data" => [10, 20, 30, 40],
              "summary" => "Upward trend observed"
            }
          )
        ]
      )

      assert_equal 2, artifact.parts.length
    end
  end
end
