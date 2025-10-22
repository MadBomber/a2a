# frozen_string_literal: true

require "test_helper"

class AgentProviderTest < Minitest::Test
  describe "initialization" do
    def test_creates_agent_provider_with_organization_only
      provider = A2A::Models::AgentProvider.new(organization: "Acme Corp")

      assert_equal "Acme Corp", provider.organization
      assert_nil provider.url
    end

    def test_creates_agent_provider_with_organization_and_url
      provider = A2A::Models::AgentProvider.new(
        organization: "Tech Company",
        url: "https://techcompany.com"
      )

      assert_equal "Tech Company", provider.organization
      assert_equal "https://techcompany.com", provider.url
    end

    def test_creates_agent_provider_with_nil_url
      provider = A2A::Models::AgentProvider.new(
        organization: "Company",
        url: nil
      )

      assert_equal "Company", provider.organization
      assert_nil provider.url
    end
  end

  describe "to_h" do
    def test_to_h_with_organization_only
      provider = A2A::Models::AgentProvider.new(organization: "Example Org")
      hash = provider.to_h

      assert_equal "Example Org", hash[:organization]
      refute hash.key?(:url)
    end

    def test_to_h_with_organization_and_url
      provider = A2A::Models::AgentProvider.new(
        organization: "Example Org",
        url: "https://example.org"
      )
      hash = provider.to_h

      assert_equal "Example Org", hash[:organization]
      assert_equal "https://example.org", hash[:url]
    end

    def test_to_h_excludes_nil_url
      provider = A2A::Models::AgentProvider.new(
        organization: "Test",
        url: nil
      )
      hash = provider.to_h

      assert hash.key?(:organization)
      refute hash.key?(:url)
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        organization: "Test Organization",
        url: "https://test.org"
      }
      provider = A2A::Models::AgentProvider.from_hash(hash)

      assert_equal "Test Organization", provider.organization
      assert_equal "https://test.org", provider.url
    end

    def test_from_hash_with_string_keys
      hash = {
        "organization" => "String Keys Org",
        "url" => "https://stringkeys.com"
      }
      provider = A2A::Models::AgentProvider.from_hash(hash)

      assert_equal "String Keys Org", provider.organization
      assert_equal "https://stringkeys.com", provider.url
    end

    def test_from_hash_with_organization_only
      hash = { organization: "Minimal Org" }
      provider = A2A::Models::AgentProvider.from_hash(hash)

      assert_equal "Minimal Org", provider.organization
      assert_nil provider.url
    end

    def test_from_hash_prefers_symbol_keys
      hash = {
        organization: "Symbol",
        "organization" => "String"
      }
      provider = A2A::Models::AgentProvider.from_hash(hash)

      assert_equal "Symbol", provider.organization
    end

    def test_from_hash_with_nil_url
      hash = {
        organization: "Test",
        url: nil
      }
      provider = A2A::Models::AgentProvider.from_hash(hash)

      assert_nil provider.url
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_organization_only
      original = A2A::Models::AgentProvider.new(organization: "Round Trip Org")

      hash = original.to_h
      restored = A2A::Models::AgentProvider.from_hash(hash)

      assert_equal original.organization, restored.organization
      assert_nil restored.url
    end

    def test_round_trip_with_organization_and_url
      original = A2A::Models::AgentProvider.new(
        organization: "Full Provider",
        url: "https://fullprovider.io"
      )

      hash = original.to_h
      restored = A2A::Models::AgentProvider.from_hash(hash)

      assert_equal original.organization, restored.organization
      assert_equal original.url, restored.url
    end
  end

  describe "edge cases" do
    def test_handles_empty_organization_string
      provider = A2A::Models::AgentProvider.new(organization: "")

      assert_equal "", provider.organization
    end

    def test_handles_long_organization_name
      long_name = "A" * 500
      provider = A2A::Models::AgentProvider.new(organization: long_name)

      assert_equal long_name, provider.organization
    end

    def test_handles_organization_with_special_characters
      provider = A2A::Models::AgentProvider.new(
        organization: "Company & Associates, LLC (2025)"
      )

      assert_equal "Company & Associates, LLC (2025)", provider.organization
    end

    def test_handles_unicode_organization_name
      provider = A2A::Models::AgentProvider.new(
        organization: "株式会社テスト"
      )

      assert_equal "株式会社テスト", provider.organization
    end

    def test_handles_various_url_formats
      urls = [
        "https://example.com",
        "http://example.org",
        "https://subdomain.example.com",
        "https://example.com/path/to/page",
        "https://example.com:8080",
        "https://example.com?query=param"
      ]

      urls.each do |url|
        provider = A2A::Models::AgentProvider.new(
          organization: "Test",
          url: url
        )
        assert_equal url, provider.url
      end
    end

    def test_handles_international_domain_names
      provider = A2A::Models::AgentProvider.new(
        organization: "Test",
        url: "https://例え.jp"
      )

      assert_equal "https://例え.jp", provider.url
    end
  end

  describe "use cases" do
    def test_represents_corporate_provider
      provider = A2A::Models::AgentProvider.new(
        organization: "Anthropic",
        url: "https://anthropic.com"
      )

      assert_equal "Anthropic", provider.organization
      assert_equal "https://anthropic.com", provider.url
    end

    def test_represents_open_source_provider
      provider = A2A::Models::AgentProvider.new(
        organization: "Open Source Community",
        url: "https://github.com/opensource/project"
      )

      assert_equal "Open Source Community", provider.organization
      assert_match(/github.com/, provider.url)
    end

    def test_represents_individual_developer
      provider = A2A::Models::AgentProvider.new(
        organization: "John Doe",
        url: "https://johndoe.dev"
      )

      assert_equal "John Doe", provider.organization
      assert_equal "https://johndoe.dev", provider.url
    end

    def test_represents_provider_without_website
      provider = A2A::Models::AgentProvider.new(
        organization: "Internal Team"
      )

      assert_equal "Internal Team", provider.organization
      assert_nil provider.url
    end

    def test_represents_enterprise_provider
      provider = A2A::Models::AgentProvider.new(
        organization: "Acme Corporation - AI Division",
        url: "https://ai.acmecorp.com"
      )

      assert_match(/AI Division/, provider.organization)
      assert_match(/ai.acmecorp.com/, provider.url)
    end
  end

  describe "attribute accessors" do
    def test_organization_reader
      provider = A2A::Models::AgentProvider.new(organization: "Test Org")
      assert_equal "Test Org", provider.organization
    end

    def test_url_reader
      provider = A2A::Models::AgentProvider.new(
        organization: "Test",
        url: "https://test.com"
      )
      assert_equal "https://test.com", provider.url
    end

    def test_url_reader_when_nil
      provider = A2A::Models::AgentProvider.new(organization: "Test")
      assert_nil provider.url
    end
  end

  describe "validation scenarios" do
    def test_organization_is_required_concept
      # While the model doesn't enforce this, the test documents expected usage
      provider = A2A::Models::AgentProvider.new(organization: "Required Org")
      assert_equal "Required Org", provider.organization
    end

    def test_url_is_optional_concept
      # URL is optional per the A2A spec
      provider = A2A::Models::AgentProvider.new(organization: "Org")
      assert_nil provider.url
    end
  end

  describe "comparison and equality" do
    def test_providers_with_same_data_have_same_hash_output
      provider1 = A2A::Models::AgentProvider.new(
        organization: "Same Corp",
        url: "https://same.com"
      )
      provider2 = A2A::Models::AgentProvider.new(
        organization: "Same Corp",
        url: "https://same.com"
      )

      assert_equal provider1.to_h, provider2.to_h
    end

    def test_providers_with_different_data_have_different_hash_output
      provider1 = A2A::Models::AgentProvider.new(organization: "Corp A")
      provider2 = A2A::Models::AgentProvider.new(organization: "Corp B")

      refute_equal provider1.to_h, provider2.to_h
    end
  end
end
