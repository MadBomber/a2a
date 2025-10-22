# frozen_string_literal: true

require_relative 'agent_capabilities'
require_relative 'agent_skill'
require_relative 'agent_provider'
require_relative 'agent_authentication'

module A2A
  module Models
    # Represents an agent's metadata and capabilities
    # Usually served at /.well-known/agent.json
    class AgentCard
      attr_reader :name, :description, :url, :provider, :version, :documentation_url,
                  :capabilities, :authentication, :default_input_modes, :default_output_modes, :skills

      def initialize(
        name:,
        url:,
        version:,
        capabilities:,
        skills:,
        description: nil,
        provider: nil,
        documentation_url: nil,
        authentication: nil,
        default_input_modes: ['text'],
        default_output_modes: ['text']
      )
        @name = name
        @description = description
        @url = url
        @provider = normalize_provider(provider)
        @version = version
        @documentation_url = documentation_url
        @capabilities = normalize_capabilities(capabilities)
        @authentication = normalize_authentication(authentication)
        @default_input_modes = default_input_modes
        @default_output_modes = default_output_modes
        @skills = normalize_skills(skills)
      end

      def to_h
        {
          name: name,
          description: description,
          url: url,
          provider: provider&.to_h,
          version: version,
          documentationUrl: documentation_url,
          capabilities: capabilities.to_h,
          authentication: authentication&.to_h,
          defaultInputModes: default_input_modes,
          defaultOutputModes: default_output_modes,
          skills: skills.map(&:to_h)
        }.compact
      end

      def to_json(*)
        to_h.to_json(*)
      end

      def self.from_hash(hash)
        new(
          name: hash[:name] || hash['name'],
          description: hash[:description] || hash['description'],
          url: hash[:url] || hash['url'],
          provider: parse_provider(hash[:provider] || hash['provider']),
          version: hash[:version] || hash['version'],
          documentation_url: hash[:documentationUrl] || hash['documentationUrl'] || hash[:documentation_url],
          capabilities: AgentCapabilities.from_hash(hash[:capabilities] || hash['capabilities']),
          authentication: parse_authentication(hash[:authentication] || hash['authentication']),
          default_input_modes: hash[:defaultInputModes] || hash['defaultInputModes'] || hash[:default_input_modes] || ['text'],
          default_output_modes: hash[:defaultOutputModes] || hash['defaultOutputModes'] || hash[:default_output_modes] || ['text'],
          skills: parse_skills(hash[:skills] || hash['skills'])
        )
      end

      private

      def normalize_capabilities(capabilities)
        return capabilities if capabilities.is_a?(AgentCapabilities)

        AgentCapabilities.new(**capabilities)
      end

      def normalize_provider(provider)
        return nil if provider.nil?
        return provider if provider.is_a?(AgentProvider)

        AgentProvider.new(**provider)
      end

      def normalize_authentication(authentication)
        return nil if authentication.nil?
        return authentication if authentication.is_a?(AgentAuthentication)

        AgentAuthentication.new(**authentication)
      end

      def normalize_skills(skills)
        skills.map do |skill|
          skill.is_a?(AgentSkill) ? skill : AgentSkill.new(**skill)
        end
      end

      def self.parse_provider(provider_hash)
        return nil if provider_hash.nil?

        AgentProvider.from_hash(provider_hash)
      end

      def self.parse_authentication(auth_hash)
        return nil if auth_hash.nil?

        AgentAuthentication.from_hash(auth_hash)
      end

      def self.parse_skills(skills_array)
        skills_array.map { |s| AgentSkill.from_hash(s) }
      end
    end
  end
end
