# frozen_string_literal: true

require "test_helper"

class AgentSkillTest < Minitest::Test
  describe "initialization" do
    def test_creates_agent_skill_with_required_fields
      skill = A2A::Models::AgentSkill.new(
        id: "skill-001",
        name: "Text Analysis"
      )

      assert_equal "skill-001", skill.id
      assert_equal "Text Analysis", skill.name
      assert_nil skill.description
      assert_nil skill.tags
      assert_nil skill.examples
      assert_nil skill.input_modes
      assert_nil skill.output_modes
    end

    def test_creates_agent_skill_with_all_fields
      skill = A2A::Models::AgentSkill.new(
        id: "skill-002",
        name: "Data Analysis",
        description: "Analyzes structured data",
        tags: ["analytics", "statistics"],
        examples: ["Analyze sales data", "Generate report"],
        input_modes: ["text", "data"],
        output_modes: ["text", "data", "file"]
      )

      assert_equal "skill-002", skill.id
      assert_equal "Data Analysis", skill.name
      assert_equal "Analyzes structured data", skill.description
      assert_equal ["analytics", "statistics"], skill.tags
      assert_equal ["Analyze sales data", "Generate report"], skill.examples
      assert_equal ["text", "data"], skill.input_modes
      assert_equal ["text", "data", "file"], skill.output_modes
    end

    def test_creates_agent_skill_with_description
      skill = A2A::Models::AgentSkill.new(
        id: "skill-003",
        name: "Translation",
        description: "Translates text between languages"
      )

      assert_equal "Translates text between languages", skill.description
    end

    def test_creates_agent_skill_with_tags
      skill = A2A::Models::AgentSkill.new(
        id: "skill-004",
        name: "Image Processing",
        tags: ["vision", "ml", "ai"]
      )

      assert_equal ["vision", "ml", "ai"], skill.tags
    end

    def test_creates_agent_skill_with_examples
      examples = [
        "Summarize this article",
        "Extract key points from text"
      ]
      skill = A2A::Models::AgentSkill.new(
        id: "skill-005",
        name: "Summarization",
        examples: examples
      )

      assert_equal examples, skill.examples
    end

    def test_creates_agent_skill_with_input_and_output_modes
      skill = A2A::Models::AgentSkill.new(
        id: "skill-006",
        name: "OCR",
        input_modes: ["file"],
        output_modes: ["text", "data"]
      )

      assert_equal ["file"], skill.input_modes
      assert_equal ["text", "data"], skill.output_modes
    end
  end

  describe "to_h" do
    def test_to_h_with_required_fields_only
      skill = A2A::Models::AgentSkill.new(
        id: "skill-001",
        name: "Basic Skill"
      )
      hash = skill.to_h

      assert_equal "skill-001", hash[:id]
      assert_equal "Basic Skill", hash[:name]
      refute hash.key?(:description)
      refute hash.key?(:tags)
      refute hash.key?(:examples)
      refute hash.key?(:inputModes)
      refute hash.key?(:outputModes)
    end

    def test_to_h_with_all_fields
      skill = A2A::Models::AgentSkill.new(
        id: "skill-002",
        name: "Advanced Skill",
        description: "A complex skill",
        tags: ["tag1", "tag2"],
        examples: ["example1", "example2"],
        input_modes: ["text"],
        output_modes: ["text", "data"]
      )
      hash = skill.to_h

      assert_equal "skill-002", hash[:id]
      assert_equal "Advanced Skill", hash[:name]
      assert_equal "A complex skill", hash[:description]
      assert_equal ["tag1", "tag2"], hash[:tags]
      assert_equal ["example1", "example2"], hash[:examples]
      assert_equal ["text"], hash[:inputModes]
      assert_equal ["text", "data"], hash[:outputModes]
    end

    def test_to_h_uses_camel_case_for_modes
      skill = A2A::Models::AgentSkill.new(
        id: "skill-003",
        name: "Test Skill",
        input_modes: ["text"],
        output_modes: ["data"]
      )
      hash = skill.to_h

      assert hash.key?(:inputModes)
      refute hash.key?(:input_modes)
      assert hash.key?(:outputModes)
      refute hash.key?(:output_modes)
    end

    def test_to_h_excludes_nil_values
      skill = A2A::Models::AgentSkill.new(
        id: "skill-004",
        name: "Skill",
        description: nil,
        tags: nil
      )
      hash = skill.to_h

      assert_equal "skill-004", hash[:id]
      assert_equal "Skill", hash[:name]
      refute hash.key?(:description)
      refute hash.key?(:tags)
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        id: "skill-001",
        name: "Parsing",
        description: "Parse structured data",
        tags: ["parser", "data"],
        examples: ["Parse JSON", "Parse XML"],
        inputModes: ["text", "file"],
        outputModes: ["data"]
      }
      skill = A2A::Models::AgentSkill.from_hash(hash)

      assert_equal "skill-001", skill.id
      assert_equal "Parsing", skill.name
      assert_equal "Parse structured data", skill.description
      assert_equal ["parser", "data"], skill.tags
      assert_equal ["Parse JSON", "Parse XML"], skill.examples
      assert_equal ["text", "file"], skill.input_modes
      assert_equal ["data"], skill.output_modes
    end

    def test_from_hash_with_string_keys
      hash = {
        "id" => "skill-002",
        "name" => "Validation",
        "description" => "Validate inputs",
        "tags" => ["validation"]
      }
      skill = A2A::Models::AgentSkill.from_hash(hash)

      assert_equal "skill-002", skill.id
      assert_equal "Validation", skill.name
      assert_equal "Validate inputs", skill.description
      assert_equal ["validation"], skill.tags
    end

    def test_from_hash_with_snake_case_keys
      hash = {
        id: "skill-003",
        name: "Conversion",
        input_modes: ["file"],
        output_modes: ["file"]
      }
      skill = A2A::Models::AgentSkill.from_hash(hash)

      assert_equal ["file"], skill.input_modes
      assert_equal ["file"], skill.output_modes
    end

    def test_from_hash_with_minimal_data
      hash = {
        id: "skill-004",
        name: "Minimal"
      }
      skill = A2A::Models::AgentSkill.from_hash(hash)

      assert_equal "skill-004", skill.id
      assert_equal "Minimal", skill.name
      assert_nil skill.description
      assert_nil skill.tags
    end

    def test_from_hash_prefers_camel_case_keys
      hash = {
        id: "skill-005",
        name: "Test",
        inputModes: ["text"],
        input_modes: ["data"]
      }
      skill = A2A::Models::AgentSkill.from_hash(hash)

      assert_equal ["text"], skill.input_modes
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_minimal_data
      original = A2A::Models::AgentSkill.new(
        id: "skill-001",
        name: "Simple Skill"
      )

      hash = original.to_h
      restored = A2A::Models::AgentSkill.from_hash(hash)

      assert_equal original.id, restored.id
      assert_equal original.name, restored.name
    end

    def test_round_trip_with_all_fields
      original = A2A::Models::AgentSkill.new(
        id: "skill-002",
        name: "Complex Skill",
        description: "A skill with all attributes",
        tags: ["complex", "featured"],
        examples: ["Example 1", "Example 2"],
        input_modes: ["text", "file"],
        output_modes: ["text", "data", "file"]
      )

      hash = original.to_h
      restored = A2A::Models::AgentSkill.from_hash(hash)

      assert_equal original.id, restored.id
      assert_equal original.name, restored.name
      assert_equal original.description, restored.description
      assert_equal original.tags, restored.tags
      assert_equal original.examples, restored.examples
      assert_equal original.input_modes, restored.input_modes
      assert_equal original.output_modes, restored.output_modes
    end
  end

  describe "edge cases" do
    def test_handles_empty_arrays
      skill = A2A::Models::AgentSkill.new(
        id: "skill-001",
        name: "Test",
        tags: [],
        examples: [],
        input_modes: [],
        output_modes: []
      )

      assert_equal [], skill.tags
      assert_equal [], skill.examples
      assert_equal [], skill.input_modes
      assert_equal [], skill.output_modes
    end

    def test_handles_long_description
      long_desc = "A" * 1000
      skill = A2A::Models::AgentSkill.new(
        id: "skill-002",
        name: "Long Description",
        description: long_desc
      )

      assert_equal long_desc, skill.description
    end

    def test_handles_many_tags
      many_tags = (1..100).map { |i| "tag#{i}" }
      skill = A2A::Models::AgentSkill.new(
        id: "skill-003",
        name: "Many Tags",
        tags: many_tags
      )

      assert_equal 100, skill.tags.length
    end

    def test_handles_special_characters_in_name
      skill = A2A::Models::AgentSkill.new(
        id: "skill-004",
        name: "Text-to-Speech & TTS (v2.0)"
      )

      assert_equal "Text-to-Speech & TTS (v2.0)", skill.name
    end

    def test_handles_unicode_in_fields
      skill = A2A::Models::AgentSkill.new(
        id: "skill-005",
        name: "翻訳 Translation",
        description: "Traducción de texto 🌍",
        tags: ["言語", "idioma"]
      )

      assert_equal "翻訳 Translation", skill.name
      assert_match(/🌍/, skill.description)
    end
  end

  describe "use cases" do
    def test_represents_text_processing_skill
      skill = A2A::Models::AgentSkill.new(
        id: "text-summarization",
        name: "Text Summarization",
        description: "Generates concise summaries of long texts",
        tags: ["nlp", "text-processing", "summarization"],
        examples: [
          "Summarize this article in 3 sentences",
          "Create a brief summary of the document"
        ],
        input_modes: ["text"],
        output_modes: ["text"]
      )

      assert_equal "text-summarization", skill.id
      assert_equal 3, skill.tags.length
      assert_equal ["text"], skill.input_modes
      assert_equal ["text"], skill.output_modes
    end

    def test_represents_data_analysis_skill
      skill = A2A::Models::AgentSkill.new(
        id: "data-analytics",
        name: "Data Analytics",
        description: "Analyzes structured data and generates insights",
        tags: ["analytics", "statistics", "data-science"],
        examples: [
          "Analyze sales trends from CSV",
          "Generate statistical summary"
        ],
        input_modes: ["file", "data"],
        output_modes: ["text", "data", "file"]
      )

      assert_equal "data-analytics", skill.id
      assert_equal 2, skill.input_modes.length
      assert_equal 3, skill.output_modes.length
    end

    def test_represents_multimodal_skill
      skill = A2A::Models::AgentSkill.new(
        id: "image-caption",
        name: "Image Captioning",
        description: "Generates text descriptions of images",
        tags: ["vision", "ai", "multimodal"],
        examples: ["Describe what's in this image"],
        input_modes: ["file"],
        output_modes: ["text", "data"]
      )

      assert_equal ["file"], skill.input_modes
      assert_includes skill.output_modes, "text"
      assert_includes skill.output_modes, "data"
    end

    def test_represents_simple_skill_without_examples
      skill = A2A::Models::AgentSkill.new(
        id: "spell-check",
        name: "Spell Checking",
        description: "Checks and corrects spelling errors",
        tags: ["text", "correction"]
      )

      assert_nil skill.examples
      assert_nil skill.input_modes
      assert_nil skill.output_modes
    end
  end

  describe "attribute accessors" do
    def test_id_reader
      skill = A2A::Models::AgentSkill.new(id: "test-id", name: "Test")
      assert_equal "test-id", skill.id
    end

    def test_name_reader
      skill = A2A::Models::AgentSkill.new(id: "test", name: "Test Name")
      assert_equal "Test Name", skill.name
    end

    def test_description_reader
      skill = A2A::Models::AgentSkill.new(
        id: "test",
        name: "Test",
        description: "Description"
      )
      assert_equal "Description", skill.description
    end

    def test_tags_reader
      skill = A2A::Models::AgentSkill.new(
        id: "test",
        name: "Test",
        tags: ["tag1", "tag2"]
      )
      assert_equal ["tag1", "tag2"], skill.tags
    end

    def test_examples_reader
      skill = A2A::Models::AgentSkill.new(
        id: "test",
        name: "Test",
        examples: ["ex1"]
      )
      assert_equal ["ex1"], skill.examples
    end

    def test_input_modes_reader
      skill = A2A::Models::AgentSkill.new(
        id: "test",
        name: "Test",
        input_modes: ["text"]
      )
      assert_equal ["text"], skill.input_modes
    end

    def test_output_modes_reader
      skill = A2A::Models::AgentSkill.new(
        id: "test",
        name: "Test",
        output_modes: ["data"]
      )
      assert_equal ["data"], skill.output_modes
    end
  end
end
