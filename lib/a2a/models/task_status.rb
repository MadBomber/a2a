# frozen_string_literal: true

require_relative 'task_state'
require_relative 'message'

module A2A
  module Models
    # Represents the status of a task, including its state, optional message, and timestamp
    class TaskStatus
      attr_reader :state, :message, :timestamp

      def initialize(state:, message: nil, timestamp: nil)
        @state = state.is_a?(TaskState) ? state : TaskState.new(state)
        @message = normalize_message(message)
        @timestamp = timestamp || Time.now.utc.iso8601
      end

      def to_h
        {
          state: state.to_s,
          message: message&.to_h,
          timestamp: timestamp
        }.compact
      end

      def to_json(*)
        to_h.to_json(*)
      end

      def self.from_hash(hash)
        new(
          state: hash[:state] || hash['state'],
          message: parse_message(hash[:message] || hash['message']),
          timestamp: hash[:timestamp] || hash['timestamp']
        )
      end

      private

      def normalize_message(message)
        return nil if message.nil?
        return message if message.is_a?(Message)

        Message.from_hash(message)
      end

      def self.parse_message(message_hash)
        return nil if message_hash.nil?

        Message.from_hash(message_hash)
      end
    end
  end
end
