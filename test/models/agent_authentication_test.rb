# frozen_string_literal: true

require "test_helper"

class AgentAuthenticationTest < Minitest::Test
  describe "initialization" do
    def test_creates_agent_authentication_with_schemes_only
      auth = A2A::Models::AgentAuthentication.new(schemes: ["bearer"])

      assert_equal ["bearer"], auth.schemes
      assert_nil auth.credentials
    end

    def test_creates_agent_authentication_with_schemes_and_credentials
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["bearer", "apikey"],
        credentials: { "token" => "secret123" }
      )

      assert_equal ["bearer", "apikey"], auth.schemes
      assert_equal({ "token" => "secret123" }, auth.credentials)
    end

    def test_creates_agent_authentication_with_nil_credentials
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["basic"],
        credentials: nil
      )

      assert_equal ["basic"], auth.schemes
      assert_nil auth.credentials
    end

    def test_creates_agent_authentication_with_single_scheme
      auth = A2A::Models::AgentAuthentication.new(schemes: ["oauth2"])

      assert_equal ["oauth2"], auth.schemes
    end

    def test_creates_agent_authentication_with_multiple_schemes
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["bearer", "basic", "apikey"]
      )

      assert_equal 3, auth.schemes.length
    end
  end

  describe "to_h" do
    def test_to_h_with_schemes_only
      auth = A2A::Models::AgentAuthentication.new(schemes: ["bearer"])
      hash = auth.to_h

      assert_equal ["bearer"], hash[:schemes]
      refute hash.key?(:credentials)
    end

    def test_to_h_with_schemes_and_credentials
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["apikey"],
        credentials: { "api_key" => "key123" }
      )
      hash = auth.to_h

      assert_equal ["apikey"], hash[:schemes]
      assert_equal({ "api_key" => "key123" }, hash[:credentials])
    end

    def test_to_h_excludes_nil_credentials
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["bearer"],
        credentials: nil
      )
      hash = auth.to_h

      assert hash.key?(:schemes)
      refute hash.key?(:credentials)
    end

    def test_to_h_with_complex_credentials
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["oauth2"],
        credentials: {
          "client_id" => "abc123",
          "client_secret" => "secret",
          "scope" => ["read", "write"]
        }
      )
      hash = auth.to_h

      assert_kind_of Hash, hash[:credentials]
      assert_equal "abc123", hash[:credentials]["client_id"]
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        schemes: ["bearer"],
        credentials: { "token" => "abc" }
      }
      auth = A2A::Models::AgentAuthentication.from_hash(hash)

      assert_equal ["bearer"], auth.schemes
      assert_equal({ "token" => "abc" }, auth.credentials)
    end

    def test_from_hash_with_string_keys
      hash = {
        "schemes" => ["basic"],
        "credentials" => { "username" => "user", "password" => "pass" }
      }
      auth = A2A::Models::AgentAuthentication.from_hash(hash)

      assert_equal ["basic"], auth.schemes
      assert_equal({ "username" => "user", "password" => "pass" }, auth.credentials)
    end

    def test_from_hash_with_schemes_only
      hash = { schemes: ["apikey"] }
      auth = A2A::Models::AgentAuthentication.from_hash(hash)

      assert_equal ["apikey"], auth.schemes
      assert_nil auth.credentials
    end

    def test_from_hash_prefers_symbol_keys
      hash = {
        schemes: ["bearer"],
        "schemes" => ["basic"]
      }
      auth = A2A::Models::AgentAuthentication.from_hash(hash)

      assert_equal ["bearer"], auth.schemes
    end

    def test_from_hash_with_nil_credentials
      hash = {
        schemes: ["bearer"],
        credentials: nil
      }
      auth = A2A::Models::AgentAuthentication.from_hash(hash)

      assert_nil auth.credentials
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_schemes_only
      original = A2A::Models::AgentAuthentication.new(
        schemes: ["bearer", "apikey"]
      )

      hash = original.to_h
      restored = A2A::Models::AgentAuthentication.from_hash(hash)

      assert_equal original.schemes, restored.schemes
      assert_nil restored.credentials
    end

    def test_round_trip_with_schemes_and_credentials
      original = A2A::Models::AgentAuthentication.new(
        schemes: ["oauth2"],
        credentials: {
          "client_id" => "test123",
          "scope" => ["read", "write"]
        }
      )

      hash = original.to_h
      restored = A2A::Models::AgentAuthentication.from_hash(hash)

      assert_equal original.schemes, restored.schemes
      assert_equal original.credentials, restored.credentials
    end
  end

  describe "edge cases" do
    def test_handles_empty_schemes_array
      auth = A2A::Models::AgentAuthentication.new(schemes: [])

      assert_equal [], auth.schemes
    end

    def test_handles_many_schemes
      many_schemes = ["bearer", "basic", "apikey", "oauth2", "digest", "custom"]
      auth = A2A::Models::AgentAuthentication.new(schemes: many_schemes)

      assert_equal 6, auth.schemes.length
    end

    def test_handles_empty_credentials_hash
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["bearer"],
        credentials: {}
      )

      assert_equal({}, auth.credentials)
    end

    def test_handles_nested_credentials
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["custom"],
        credentials: {
          "oauth" => {
            "provider" => "google",
            "scopes" => ["email", "profile"]
          }
        }
      )

      assert_kind_of Hash, auth.credentials["oauth"]
    end

    def test_handles_scheme_name_variations
      schemes = [
        "bearer",
        "Bearer",
        "BEARER",
        "api-key",
        "API_KEY",
        "custom-scheme-v2"
      ]
      auth = A2A::Models::AgentAuthentication.new(schemes: schemes)

      assert_equal 6, auth.schemes.length
    end
  end

  describe "use cases" do
    def test_represents_bearer_token_auth
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["bearer"]
      )

      assert_equal ["bearer"], auth.schemes
      assert_nil auth.credentials
    end

    def test_represents_api_key_auth
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["apikey"],
        credentials: { "header" => "X-API-Key" }
      )

      assert_equal ["apikey"], auth.schemes
      assert_equal "X-API-Key", auth.credentials["header"]
    end

    def test_represents_basic_auth
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["basic"]
      )

      assert_equal ["basic"], auth.schemes
    end

    def test_represents_oauth2_auth
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["oauth2"],
        credentials: {
          "authorization_endpoint" => "https://oauth.example.com/authorize",
          "token_endpoint" => "https://oauth.example.com/token",
          "scopes" => ["read", "write"]
        }
      )

      assert_equal ["oauth2"], auth.schemes
      assert_includes auth.credentials, "authorization_endpoint"
      assert_includes auth.credentials, "scopes"
    end

    def test_represents_multiple_auth_schemes
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["bearer", "apikey", "basic"]
      )

      assert_equal 3, auth.schemes.length
      assert_includes auth.schemes, "bearer"
      assert_includes auth.schemes, "apikey"
      assert_includes auth.schemes, "basic"
    end

    def test_represents_custom_auth_scheme
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["custom-jwt"],
        credentials: {
          "algorithm" => "RS256",
          "issuer" => "https://auth.example.com",
          "audience" => "api.example.com"
        }
      )

      assert_equal ["custom-jwt"], auth.schemes
      assert_equal "RS256", auth.credentials["algorithm"]
    end

    def test_represents_no_auth_required
      # While uncommon, an agent might list empty schemes
      auth = A2A::Models::AgentAuthentication.new(schemes: [])

      assert_equal [], auth.schemes
    end
  end

  describe "attribute accessors" do
    def test_schemes_reader
      auth = A2A::Models::AgentAuthentication.new(schemes: ["bearer"])
      assert_equal ["bearer"], auth.schemes
    end

    def test_credentials_reader
      creds = { "token" => "abc123" }
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["bearer"],
        credentials: creds
      )
      assert_equal creds, auth.credentials
    end

    def test_credentials_reader_when_nil
      auth = A2A::Models::AgentAuthentication.new(schemes: ["bearer"])
      assert_nil auth.credentials
    end
  end

  describe "security considerations" do
    def test_does_not_expose_sensitive_data_in_tests
      # This test documents that credentials should be handled carefully
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["bearer"],
        credentials: { "secret_token" => "super-secret-value" }
      )

      # The model stores credentials as provided
      assert_equal "super-secret-value", auth.credentials["secret_token"]

      # In production, care should be taken not to log or expose this
      hash = auth.to_h
      assert hash[:credentials]["secret_token"]
    end

    def test_credentials_are_preserved_exactly
      # Credentials should not be modified by the model
      original_creds = {
        "key" => "value",
        "nested" => { "data" => "preserved" }
      }
      auth = A2A::Models::AgentAuthentication.new(
        schemes: ["custom"],
        credentials: original_creds
      )

      assert_equal original_creds, auth.credentials
    end
  end
end
