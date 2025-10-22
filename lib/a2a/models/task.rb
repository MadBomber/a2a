# frozen_string_literal: true

require_relative 'task_status'
require_relative 'artifact'

module A2A
  module Models
    # Represents a task in the A2A protocol
    # The central unit of work with unique ID and progress through states
    class Task
      attr_reader :id, :session_id, :status, :artifacts, :metadata

      def initialize(id:, status:, session_id: nil, artifacts: nil, metadata: nil)
        @id = id
        @session_id = session_id
        @status = status.is_a?(TaskStatus) ? status : TaskStatus.new(**status)
        @artifacts = normalize_artifacts(artifacts)
        @metadata = metadata
      end

      def state
        status.state
      end

      def to_h
        {
          id: id,
          sessionId: session_id,
          status: status.to_h,
          artifacts: artifacts&.map(&:to_h),
          metadata: metadata
        }.compact
      end

      def to_json(*)
        to_h.to_json(*)
      end

      def self.from_hash(hash)
        new(
          id: hash[:id] || hash['id'],
          session_id: hash[:sessionId] || hash['sessionId'] || hash[:session_id],
          status: TaskStatus.from_hash(hash[:status] || hash['status']),
          artifacts: parse_artifacts(hash[:artifacts] || hash['artifacts']),
          metadata: hash[:metadata] || hash['metadata']
        )
      end

      private

      def normalize_artifacts(artifacts)
        return nil if artifacts.nil?
        return artifacts if artifacts.empty?

        artifacts.map do |artifact|
          artifact.is_a?(Artifact) ? artifact : Artifact.from_hash(artifact)
        end
      end

      def self.parse_artifacts(artifacts_array)
        return nil if artifacts_array.nil?

        artifacts_array.map { |a| Artifact.from_hash(a) }
      end
    end
  end
end
