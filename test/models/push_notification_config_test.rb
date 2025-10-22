# frozen_string_literal: true

require "test_helper"

class PushNotificationConfigTest < Minitest::Test
  describe "initialization" do
    def test_creates_push_notification_config_with_url_only
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://notifications.example.com/webhook"
      )

      assert_equal "https://notifications.example.com/webhook", config.url
      assert_nil config.token
      assert_nil config.authentication
    end

    def test_creates_push_notification_config_with_token
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://webhook.example.com",
        token: "secret-token-123"
      )

      assert_equal "https://webhook.example.com", config.url
      assert_equal "secret-token-123", config.token
    end

    def test_creates_push_notification_config_with_authentication
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://webhook.example.com",
        authentication: { "type" => "bearer", "token" => "abc123" }
      )

      assert_equal "https://webhook.example.com", config.url
      assert_equal({ "type" => "bearer", "token" => "abc123" }, config.authentication)
    end

    def test_creates_push_notification_config_with_all_fields
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://complete.example.com/hook",
        token: "my-token",
        authentication: { "scheme" => "custom" }
      )

      assert_equal "https://complete.example.com/hook", config.url
      assert_equal "my-token", config.token
      assert_equal({ "scheme" => "custom" }, config.authentication)
    end

    def test_creates_push_notification_config_with_nil_optional_fields
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://test.com",
        token: nil,
        authentication: nil
      )

      assert_nil config.token
      assert_nil config.authentication
    end
  end

  describe "to_h" do
    def test_to_h_with_url_only
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://webhook.example.com"
      )
      hash = config.to_h

      assert_equal "https://webhook.example.com", hash[:url]
      refute hash.key?(:token)
      refute hash.key?(:authentication)
    end

    def test_to_h_with_url_and_token
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://webhook.example.com",
        token: "token123"
      )
      hash = config.to_h

      assert_equal "https://webhook.example.com", hash[:url]
      assert_equal "token123", hash[:token]
      refute hash.key?(:authentication)
    end

    def test_to_h_with_url_and_authentication
      auth = { "type" => "bearer", "value" => "secret" }
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://webhook.example.com",
        authentication: auth
      )
      hash = config.to_h

      assert_equal "https://webhook.example.com", hash[:url]
      assert_equal auth, hash[:authentication]
      refute hash.key?(:token)
    end

    def test_to_h_with_all_fields
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://complete.example.com",
        token: "complete-token",
        authentication: { "method" => "custom" }
      )
      hash = config.to_h

      assert_equal "https://complete.example.com", hash[:url]
      assert_equal "complete-token", hash[:token]
      assert_equal({ "method" => "custom" }, hash[:authentication])
    end

    def test_to_h_excludes_nil_values
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://test.com",
        token: nil,
        authentication: nil
      )
      hash = config.to_h

      assert hash.key?(:url)
      refute hash.key?(:token)
      refute hash.key?(:authentication)
    end
  end

  describe "from_hash" do
    def test_from_hash_with_symbol_keys
      hash = {
        url: "https://notifications.example.com",
        token: "symbol-token",
        authentication: { "scheme" => "bearer" }
      }
      config = A2A::Models::PushNotificationConfig.from_hash(hash)

      assert_equal "https://notifications.example.com", config.url
      assert_equal "symbol-token", config.token
      assert_equal({ "scheme" => "bearer" }, config.authentication)
    end

    def test_from_hash_with_string_keys
      hash = {
        "url" => "https://string.example.com",
        "token" => "string-token",
        "authentication" => { "type" => "apikey" }
      }
      config = A2A::Models::PushNotificationConfig.from_hash(hash)

      assert_equal "https://string.example.com", config.url
      assert_equal "string-token", config.token
      assert_equal({ "type" => "apikey" }, config.authentication)
    end

    def test_from_hash_with_url_only
      hash = { url: "https://minimal.example.com" }
      config = A2A::Models::PushNotificationConfig.from_hash(hash)

      assert_equal "https://minimal.example.com", config.url
      assert_nil config.token
      assert_nil config.authentication
    end

    def test_from_hash_prefers_symbol_keys
      hash = {
        url: "https://symbol.com",
        "url" => "https://string.com"
      }
      config = A2A::Models::PushNotificationConfig.from_hash(hash)

      assert_equal "https://symbol.com", config.url
    end

    def test_from_hash_with_nil_token
      hash = {
        url: "https://test.com",
        token: nil
      }
      config = A2A::Models::PushNotificationConfig.from_hash(hash)

      assert_nil config.token
    end
  end

  describe "serialization round-trip" do
    def test_round_trip_with_url_only
      original = A2A::Models::PushNotificationConfig.new(
        url: "https://roundtrip.example.com"
      )

      hash = original.to_h
      restored = A2A::Models::PushNotificationConfig.from_hash(hash)

      assert_equal original.url, restored.url
      assert_nil restored.token
      assert_nil restored.authentication
    end

    def test_round_trip_with_all_fields
      original = A2A::Models::PushNotificationConfig.new(
        url: "https://complete.example.com/webhook",
        token: "roundtrip-token",
        authentication: {
          "type" => "bearer",
          "header" => "Authorization"
        }
      )

      hash = original.to_h
      restored = A2A::Models::PushNotificationConfig.from_hash(hash)

      assert_equal original.url, restored.url
      assert_equal original.token, restored.token
      assert_equal original.authentication, restored.authentication
    end
  end

  describe "edge cases" do
    def test_handles_various_url_formats
      urls = [
        "https://webhook.example.com",
        "http://localhost:3000/webhook",
        "https://api.example.com/v1/notifications",
        "https://subdomain.example.com/path/to/webhook",
        "https://example.com:8443/webhook",
        "https://webhook.example.com?client=abc"
      ]

      urls.each do |url|
        config = A2A::Models::PushNotificationConfig.new(url: url)
        assert_equal url, config.url
      end
    end

    def test_handles_long_token
      long_token = "a" * 500
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://test.com",
        token: long_token
      )

      assert_equal long_token, config.token
    end

    def test_handles_empty_authentication_hash
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://test.com",
        authentication: {}
      )

      assert_equal({}, config.authentication)
    end

    def test_handles_complex_authentication
      auth = {
        "type" => "oauth2",
        "client_id" => "client123",
        "scopes" => ["notifications:write"],
        "token_url" => "https://auth.example.com/token"
      }
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://webhook.example.com",
        authentication: auth
      )

      assert_equal auth, config.authentication
    end

    def test_handles_international_urls
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://例え.jp/webhook"
      )

      assert_equal "https://例え.jp/webhook", config.url
    end
  end

  describe "use cases" do
    def test_represents_simple_webhook
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://myapp.example.com/api/a2a/notifications"
      )

      assert_equal "https://myapp.example.com/api/a2a/notifications", config.url
      assert_nil config.token
      assert_nil config.authentication
    end

    def test_represents_webhook_with_token
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://webhook.example.com/receive",
        token: "verify-me-with-this-token"
      )

      assert_equal "verify-me-with-this-token", config.token
    end

    def test_represents_webhook_with_bearer_auth
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://secure.example.com/webhook",
        authentication: {
          "type" => "bearer",
          "token" => "bearer-token-here"
        }
      )

      assert_equal "bearer", config.authentication["type"]
      assert_includes config.authentication, "token"
    end

    def test_represents_webhook_with_custom_auth
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://custom.example.com/hook",
        authentication: {
          "type" => "custom",
          "header" => "X-Custom-Auth",
          "value" => "custom-secret"
        }
      )

      assert_equal "custom", config.authentication["type"]
      assert_equal "X-Custom-Auth", config.authentication["header"]
    end

    def test_represents_localhost_webhook_for_development
      config = A2A::Models::PushNotificationConfig.new(
        url: "http://localhost:3000/notifications"
      )

      assert_match(/localhost/, config.url)
    end
  end

  describe "attribute accessors" do
    def test_url_reader
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://test.com"
      )
      assert_equal "https://test.com", config.url
    end

    def test_token_reader
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://test.com",
        token: "test-token"
      )
      assert_equal "test-token", config.token
    end

    def test_token_reader_when_nil
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://test.com"
      )
      assert_nil config.token
    end

    def test_authentication_reader
      auth = { "type" => "bearer" }
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://test.com",
        authentication: auth
      )
      assert_equal auth, config.authentication
    end

    def test_authentication_reader_when_nil
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://test.com"
      )
      assert_nil config.authentication
    end
  end

  describe "security considerations" do
    def test_preserves_sensitive_token
      # This test documents that tokens are stored as-is
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://test.com",
        token: "super-secret-token"
      )

      assert_equal "super-secret-token", config.token

      # The model does not hide or encrypt tokens
      hash = config.to_h
      assert_equal "super-secret-token", hash[:token]
    end

    def test_preserves_authentication_credentials
      # Authentication data is preserved exactly
      auth = {
        "type" => "bearer",
        "token" => "sensitive-bearer-token"
      }
      config = A2A::Models::PushNotificationConfig.new(
        url: "https://test.com",
        authentication: auth
      )

      assert_equal auth, config.authentication
    end
  end
end
