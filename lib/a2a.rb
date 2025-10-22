# frozen_string_literal: true

require_relative 'a2a/version'
require_relative 'a2a/error'

# Models
require_relative 'a2a/models/task_state'
require_relative 'a2a/models/part'
require_relative 'a2a/models/text_part'
require_relative 'a2a/models/file_content'
require_relative 'a2a/models/file_part'
require_relative 'a2a/models/data_part'
require_relative 'a2a/models/message'
require_relative 'a2a/models/artifact'
require_relative 'a2a/models/task_status'
require_relative 'a2a/models/task'
require_relative 'a2a/models/agent_authentication'
require_relative 'a2a/models/agent_provider'
require_relative 'a2a/models/agent_capabilities'
require_relative 'a2a/models/agent_skill'
require_relative 'a2a/models/agent_card'
require_relative 'a2a/models/push_notification_config'

# Protocol
require_relative 'a2a/protocol/error'
require_relative 'a2a/protocol/request'
require_relative 'a2a/protocol/response'

# Client and Server
require_relative 'a2a/client/base'
require_relative 'a2a/server/base'

# Implementation of the A2A (Agent2Agent) protocol
# An open protocol enabling communication and interoperability between opaque agentic applications
module A2A
  class << self
    # Returns the gem version
    def version
      VERSION
    end
  end
end
