# frozen_string_literal: true

module A2A
  module Models
    # Represents the state of a task in the A2A protocol
    # Valid states: submitted, working, input-required, completed, canceled, failed, unknown
    class TaskState
      STATES = %w[
        submitted
        working
        input-required
        completed
        canceled
        failed
        unknown
      ].freeze

      attr_reader :value

      def initialize(value)
        @value = validate_state(value)
      end

      def to_s
        @value
      end

      def to_json(*_args)
        @value
      end

      def ==(other)
        return false unless other.is_a?(TaskState)

        @value == other.value
      end

      def submitted?
        @value == 'submitted'
      end

      def working?
        @value == 'working'
      end

      def input_required?
        @value == 'input-required'
      end

      def completed?
        @value == 'completed'
      end

      def canceled?
        @value == 'canceled'
      end

      def failed?
        @value == 'failed'
      end

      def unknown?
        @value == 'unknown'
      end

      def terminal?
        completed? || canceled? || failed?
      end

      private

      def validate_state(value)
        unless STATES.include?(value)
          raise ArgumentError, "Invalid task state: #{value}. Must be one of: #{STATES.join(', ')}"
        end

        value
      end
    end
  end
end
