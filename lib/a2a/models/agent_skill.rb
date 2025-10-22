# frozen_string_literal: true

module A2A
  module Models
    # Represents a skill that an agent can perform
    class AgentSkill
      attr_reader :id, :name, :description, :tags, :examples, :input_modes, :output_modes

      def initialize(
        id:,
        name:,
        description: nil,
        tags: nil,
        examples: nil,
        input_modes: nil,
        output_modes: nil
      )
        @id = id
        @name = name
        @description = description
        @tags = tags
        @examples = examples
        @input_modes = input_modes
        @output_modes = output_modes
      end

      def to_h
        {
          id: id,
          name: name,
          description: description,
          tags: tags,
          examples: examples,
          inputModes: input_modes,
          outputModes: output_modes
        }.compact
      end

      def to_json(*)
        to_h.to_json(*)
      end

      def self.from_hash(hash)
        new(
          id: hash[:id] || hash['id'],
          name: hash[:name] || hash['name'],
          description: hash[:description] || hash['description'],
          tags: hash[:tags] || hash['tags'],
          examples: hash[:examples] || hash['examples'],
          input_modes: hash[:inputModes] || hash['inputModes'] || hash[:input_modes],
          output_modes: hash[:outputModes] || hash['outputModes'] || hash[:output_modes]
        )
      end
    end
  end
end
