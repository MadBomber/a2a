# frozen_string_literal: true

require "test_helper"

class AgentCardTest < Minitest::Test
  describe "initialization" do
    def test_creates_agent_card_with_required_fields
      card = A2A::Models::AgentCard.new(
        name: "Test Agent",
        url: "https://test.example.com/a2a",
        version: "1.0.0",
        capabilities: { streaming: false },
        skills: []
      )

      assert_equal "Test Agent", card.name
      assert_equal "https://test.example.com/a2a", card.url
      assert_equal "1.0.0", card.version
      assert_kind_of A2A::Models::AgentCapabilities, card.capabilities
      assert_equal [], card.skills
    end

    def test_creates_agent_card_with_all_fields
      card = A2A::Models::AgentCard.new(
        name: "Full Agent",
        description: "A fully featured agent",
        url: "https://full.example.com/a2a",
        provider: { organization: "Test Org", url: "https://testorg.com" },
        version: "2.0.0",
        documentation_url: "https://docs.example.com",
        capabilities: { streaming: true, push_notifications: true },
        authentication: { schemes: ["bearer"] },
        default_input_modes: %w[text file],
        default_output_modes: %w[text data],
        skills: [{ id: "skill-1", name: "Skill 1" }]
      )

      assert_equal "Full Agent", card.name
      assert_equal "A fully featured agent", card.description
      assert_kind_of A2A::Models::AgentProvider, card.provider
      assert_equal "2.0.0", card.version
      assert_equal "https://docs.example.com", card.documentation_url
      assert card.capabilities.streaming?
      assert_kind_of A2A::Models::AgentAuthentication, card.authentication
      assert_equal %w[text file], card.default_input_modes
      assert_equal %w[text data], card.default_output_modes
      assert_equal 1, card.skills.length
    end

    def test_normalizes_capabilities_hash
      card = A2A::Models::AgentCard.new(
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        capabilities: { streaming: true },
        skills: []
      )

      assert_kind_of A2A::Models::AgentCapabilities, card.capabilities
      assert card.capabilities.streaming?
    end

    def test_normalizes_provider_hash
      card = A2A::Models::AgentCard.new(
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        provider: { organization: "Acme" },
        capabilities: {},
        skills: []
      )

      assert_kind_of A2A::Models::AgentProvider, card.provider
      assert_equal "Acme", card.provider.organization
    end

    def test_normalizes_authentication_hash
      card = A2A::Models::AgentCard.new(
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        capabilities: {},
        authentication: { schemes: ["bearer"] },
        skills: []
      )

      assert_kind_of A2A::Models::AgentAuthentication, card.authentication
      assert_equal ["bearer"], card.authentication.schemes
    end

    def test_normalizes_skills_hashes
      card = A2A::Models::AgentCard.new(
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        capabilities: {},
        skills: [
          { id: "skill-1", name: "Skill 1" },
          { id: "skill-2", name: "Skill 2" }
        ]
      )

      assert_equal 2, card.skills.length
      assert_kind_of A2A::Models::AgentSkill, card.skills.first
      assert_equal "skill-1", card.skills.first.id
    end

    def test_default_input_modes
      card = A2A::Models::AgentCard.new(
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        capabilities: {},
        skills: []
      )

      assert_equal ["text"], card.default_input_modes
    end

    def test_default_output_modes
      card = A2A::Models::AgentCard.new(
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        capabilities: {},
        skills: []
      )

      assert_equal ["text"], card.default_output_modes
    end
  end

  describe "to_h" do
    def test_to_h_with_minimal_fields
      card = A2A::Models::AgentCard.new(
        name: "Minimal Agent",
        url: "https://minimal.com/a2a",
        version: "1.0.0",
        capabilities: { streaming: false },
        skills: []
      )
      hash = card.to_h

      assert_equal "Minimal Agent", hash[:name]
      assert_equal "https://minimal.com/a2a", hash[:url]
      assert_equal "1.0.0", hash[:version]
      assert_kind_of Hash, hash[:capabilities]
      assert_equal ["text"], hash[:defaultInputModes]
      assert_equal ["text"], hash[:defaultOutputModes]
      assert_equal [], hash[:skills]
      refute hash.key?(:description)
      refute hash.key?(:provider)
      refute hash.key?(:authentication)
    end

    def test_to_h_with_all_fields
      card = A2A::Models::AgentCard.new(
        name: "Complete Agent",
        description: "Complete test agent",
        url: "https://complete.com/a2a",
        provider: { organization: "Test Org" },
        version: "2.0.0",
        documentation_url: "https://docs.complete.com",
        capabilities: { streaming: true },
        authentication: { schemes: ["bearer"] },
        default_input_modes: %w[text file],
        default_output_modes: %w[text data],
        skills: [{ id: "skill-1", name: "Test Skill" }]
      )
      hash = card.to_h

      assert_equal "Complete Agent", hash[:name]
      assert_equal "Complete test agent", hash[:description]
      assert_equal "https://complete.com/a2a", hash[:url]
      assert_kind_of Hash, hash[:provider]
      assert_equal "2.0.0", hash[:version]
      assert_equal "https://docs.complete.com", hash[:documentationUrl]
      assert_kind_of Hash, hash[:capabilities]
      assert_kind_of Hash, hash[:authentication]
      assert_equal %w[text file], hash[:defaultInputModes]
      assert_equal %w[text data], hash[:defaultOutputModes]
      assert_equal 1, hash[:skills].length
    end

    def test_to_h_uses_camel_case_keys
      card = A2A::Models::AgentCard.new(
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        documentation_url: "https://docs.test.com",
        capabilities: {},
        default_input_modes: ["text"],
        default_output_modes: ["data"],
        skills: []
      )
      hash = card.to_h

      assert hash.key?(:documentationUrl)
      refute hash.key?(:documentation_url)
      assert hash.key?(:defaultInputModes)
      refute hash.key?(:default_input_modes)
      assert hash.key?(:defaultOutputModes)
      refute hash.key?(:default_output_modes)
    end

    def test_to_h_excludes_nil_values
      card = A2A::Models::AgentCard.new(
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        capabilities: {},
        skills: []
      )
      hash = card.to_h

      refute hash.key?(:description)
      refute hash.key?(:provider)
      refute hash.key?(:documentationUrl)
      refute hash.key?(:authentication)
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        name: "Test Agent",
        url: "https://test.com/a2a",
        version: "1.0.0",
        capabilities: { streaming: true },
        skills: [{ id: "skill-1", name: "Test" }]
      }
      card = A2A::Models::AgentCard.from_hash(hash)

      assert_equal "Test Agent", card.name
      assert_equal "https://test.com/a2a", card.url
      assert_equal "1.0.0", card.version
      assert card.capabilities.streaming?
      assert_equal 1, card.skills.length
    end

    def test_from_hash_with_string_keys
      hash = {
        "name" => "String Agent",
        "url" => "https://string.com/a2a",
        "version" => "2.0",
        "capabilities" => { "streaming" => false },
        "skills" => []
      }
      card = A2A::Models::AgentCard.from_hash(hash)

      assert_equal "String Agent", card.name
      assert_equal "https://string.com/a2a", card.url
      assert_equal "2.0", card.version
    end

    def test_from_hash_with_camel_case_keys
      hash = {
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        documentationUrl: "https://docs.test.com",
        capabilities: {},
        defaultInputModes: %w[text file],
        defaultOutputModes: %w[text data],
        skills: []
      }
      card = A2A::Models::AgentCard.from_hash(hash)

      assert_equal "https://docs.test.com", card.documentation_url
      assert_equal %w[text file], card.default_input_modes
      assert_equal %w[text data], card.default_output_modes
    end

    def test_from_hash_with_snake_case_keys
      hash = {
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        documentation_url: "https://docs.test.com",
        capabilities: {},
        default_input_modes: ["file"],
        default_output_modes: ["file"],
        skills: []
      }
      card = A2A::Models::AgentCard.from_hash(hash)

      assert_equal "https://docs.test.com", card.documentation_url
      assert_equal ["file"], card.default_input_modes
      assert_equal ["file"], card.default_output_modes
    end

    def test_from_hash_with_nested_objects
      hash = {
        name: "Nested",
        url: "https://nested.com",
        version: "1.0",
        provider: {
          organization: "Test Org",
          url: "https://org.com"
        },
        capabilities: {
          streaming: true,
          pushNotifications: true
        },
        authentication: {
          schemes: %w[bearer apikey]
        },
        skills: [
          { id: "s1", name: "Skill 1" },
          { id: "s2", name: "Skill 2" }
        ]
      }
      card = A2A::Models::AgentCard.from_hash(hash)

      assert_kind_of A2A::Models::AgentProvider, card.provider
      assert_kind_of A2A::Models::AgentCapabilities, card.capabilities
      assert_kind_of A2A::Models::AgentAuthentication, card.authentication
      assert_equal 2, card.skills.length
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_minimal_data
      original = A2A::Models::AgentCard.new(
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        capabilities: { streaming: false },
        skills: []
      )

      hash = original.to_h
      restored = A2A::Models::AgentCard.from_hash(hash)

      assert_equal original.name, restored.name
      assert_equal original.url, restored.url
      assert_equal original.version, restored.version
      assert_equal original.capabilities.streaming, restored.capabilities.streaming
    end

    def test_round_trip_with_complete_data
      original = A2A::Models::AgentCard.new(
        name: "Complete",
        description: "Complete agent card",
        url: "https://complete.com",
        provider: { organization: "Org", url: "https://org.com" },
        version: "2.0",
        documentation_url: "https://docs.com",
        capabilities: { streaming: true, push_notifications: true },
        authentication: { schemes: ["bearer"] },
        default_input_modes: %w[text file],
        default_output_modes: %w[text data],
        skills: [
          { id: "s1", name: "Skill 1", description: "First skill" }
        ]
      )

      hash = original.to_h
      restored = A2A::Models::AgentCard.from_hash(hash)

      assert_equal original.name, restored.name
      assert_equal original.description, restored.description
      assert_equal original.provider.organization, restored.provider.organization
      assert_equal original.version, restored.version
      assert_equal original.documentation_url, restored.documentation_url
      assert_equal original.default_input_modes, restored.default_input_modes
      assert_equal original.default_output_modes, restored.default_output_modes
      assert_equal original.skills.length, restored.skills.length
    end
  end

  describe "use cases" do
    def test_represents_simple_text_agent
      card = A2A::Models::AgentCard.new(
        name: "Simple Text Agent",
        description: "A basic agent that processes text",
        url: "https://simple.example.com/a2a",
        version: "1.0.0",
        capabilities: { streaming: false },
        skills: [
          {
            id: "text-analysis",
            name: "Text Analysis",
            description: "Analyzes text content",
            input_modes: ["text"],
            output_modes: ["text"]
          }
        ]
      )

      assert_equal "Simple Text Agent", card.name
      refute card.capabilities.streaming?
      assert_equal 1, card.skills.length
    end

    def test_represents_streaming_agent
      card = A2A::Models::AgentCard.new(
        name: "Streaming Agent",
        url: "https://streaming.example.com/a2a",
        version: "2.0.0",
        capabilities: { streaming: true },
        skills: []
      )

      assert card.capabilities.streaming?
    end

    def test_represents_multimodal_agent
      card = A2A::Models::AgentCard.new(
        name: "Multimodal Agent",
        description: "Processes text, images, and data",
        url: "https://multimodal.example.com/a2a",
        version: "3.0.0",
        capabilities: { streaming: true, push_notifications: true },
        default_input_modes: %w[text file data],
        default_output_modes: %w[text file data],
        skills: [
          { id: "image-analysis", name: "Image Analysis" },
          { id: "data-processing", name: "Data Processing" }
        ]
      )

      assert_includes card.default_input_modes, "file"
      assert_includes card.default_output_modes, "data"
      assert_equal 2, card.skills.length
    end

    def test_represents_enterprise_agent
      card = A2A::Models::AgentCard.new(
        name: "Enterprise AI Agent",
        description: "Enterprise-grade AI assistant",
        url: "https://enterprise.example.com/a2a",
        provider: {
          organization: "Enterprise Corp",
          url: "https://enterprise.com"
        },
        version: "1.5.2",
        documentation_url: "https://docs.enterprise.com/ai-agent",
        capabilities: {
          streaming: true,
          push_notifications: true,
          state_transition_history: true
        },
        authentication: {
          schemes: %w[bearer oauth2]
        },
        skills: [
          {
            id: "enterprise-search",
            name: "Enterprise Search",
            tags: %w[search enterprise]
          }
        ]
      )

      assert_equal "Enterprise Corp", card.provider.organization
      assert card.capabilities.state_transition_history?
      assert_includes card.authentication.schemes, "oauth2"
    end
  end

  describe "edge cases" do
    def test_handles_empty_skills_array
      card = A2A::Models::AgentCard.new(
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        capabilities: {},
        skills: []
      )

      assert_equal [], card.skills
    end

    def test_handles_many_skills
      skills = (1..10).map do |i|
        { id: "skill-#{i}", name: "Skill #{i}" }
      end

      card = A2A::Models::AgentCard.new(
        name: "Test",
        url: "https://test.com",
        version: "1.0",
        capabilities: {},
        skills: skills
      )

      assert_equal 10, card.skills.length
    end

    def test_handles_unicode_content
      card = A2A::Models::AgentCard.new(
        name: "AIエージェント",
        description: "日本語対応のエージェント",
        url: "https://test.jp/a2a",
        version: "1.0",
        capabilities: {},
        skills: []
      )

      assert_match(/エージェント/, card.name)
      assert_match(/日本語/, card.description)
    end
  end
end
