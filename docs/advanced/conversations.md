# Multi-Turn Conversations with Session Management

Comprehensive guide to implementing stateful multi-turn conversations and session management in the A2A protocol.

## Table of Contents

- [Overview](#overview)
- [When to Use Sessions](#when-to-use-sessions)
- [Architecture](#architecture)
- [Session Lifecycle](#session-lifecycle)
- [Implementation Guide](#implementation-guide)
  - [Server-Side Session Management](#server-side-session-management)
  - [Client-Side Session Handling](#client-side-session-handling)
- [Context Management](#context-management)
- [State Handling](#state-handling)
- [Best Practices](#best-practices)
- [Complete Examples](#complete-examples)
- [Testing Strategies](#testing-strategies)
- [Troubleshooting](#troubleshooting)

## Overview

Multi-turn conversations allow agents and clients to maintain context across multiple task exchanges. The A2A protocol supports sessions through the `sessionId` field in tasks, enabling agents to remember previous interactions and provide contextually aware responses.

### Session Concept

A **session** represents a logical conversation boundary. All tasks with the same `sessionId` belong to the same conversation and share context.

```ruby
# First turn in conversation
task1 = A2A::Models::Task.new(
  id: "task-1",
  session_id: "session-abc123",  # Session identifier
  status: { state: "submitted" }
)

# Second turn in same conversation
task2 = A2A::Models::Task.new(
  id: "task-2",
  session_id: "session-abc123",  # Same session
  status: { state: "submitted" }
)

# New conversation
task3 = A2A::Models::Task.new(
  id: "task-3",
  session_id: "session-xyz789",  # Different session
  status: { state: "submitted" }
)
```

## When to Use Sessions

Sessions are ideal for:

1. **Interactive Conversations**: Back-and-forth dialogue between user and agent
2. **Multi-Step Workflows**: Tasks that require multiple turns to complete
3. **Context-Dependent Tasks**: Where previous turns inform current responses
4. **Progressive Refinement**: Iterative improvement based on feedback
5. **Input-Required States**: When agent needs clarification or additional data

**Don't use sessions for**:
- One-off independent requests
- Tasks that don't benefit from context
- High-volume stateless operations

## Architecture

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 700" style="background:transparent">
  <!-- Client -->
  <rect x="50" y="50" width="150" height="80" fill="#1e3a8a" stroke="#3b82f6" stroke-width="2" rx="5"/>
  <text x="125" y="95" text-anchor="middle" fill="#fff" font-family="Arial" font-size="16" font-weight="bold">A2A Client</text>

  <!-- Server -->
  <rect x="800" y="50" width="150" height="80" fill="#1e3a8a" stroke="#3b82f6" stroke-width="2" rx="5"/>
  <text x="875" y="95" text-anchor="middle" fill="#fff" font-family="Arial" font-size="16" font-weight="bold">A2A Server</text>

  <!-- Session Store -->
  <rect x="800" y="200" width="150" height="80" fill="#7c3aed" stroke="#a78bfa" stroke-width="2" rx="5"/>
  <text x="875" y="235" text-anchor="middle" fill="#fff" font-family="Arial" font-size="14" font-weight="bold">Session Store</text>
  <text x="875" y="255" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12">(Context + State)</text>

  <!-- Agent -->
  <rect x="800" y="550" width="150" height="80" fill="#064e3b" stroke="#10b981" stroke-width="2" rx="5"/>
  <text x="875" y="595" text-anchor="middle" fill="#fff" font-family="Arial" font-size="16" font-weight="bold">Agent Core</text>

  <!-- Turn 1: Initial Request -->
  <line x1="200" y1="90" x2="790" y2="90" stroke="#3b82f6" stroke-width="2" marker-end="url(#arrowblue)"/>
  <text x="495" y="75" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">1. task-1 (session-abc)</text>

  <!-- Create Session -->
  <line x1="875" y1="130" x2="875" y2="190" stroke="#a78bfa" stroke-width="2" stroke-dasharray="5,5" marker-end="url(#arrowpurple)"/>
  <text x="905" y="160" fill="#fff" font-family="Arial" font-size="11">Create</text>

  <!-- Process -->
  <line x1="875" y1="280" x2="875" y2="540" stroke="#f59e0b" stroke-width="2" marker-end="url(#arroworange)"/>

  <!-- Response 1 -->
  <line x1="790" y1="110" x2="210" y2="110" stroke="#10b981" stroke-width="2" stroke-dasharray="5,5"/>
  <text x="495" y="125" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">2. Response (input-required)</text>

  <!-- Turn 2: Follow-up -->
  <line x1="200" y1="180" x2="790" y2="180" stroke="#3b82f6" stroke-width="2" marker-end="url(#arrowblue)"/>
  <text x="495" y="165" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">3. task-2 (session-abc) + user input</text>

  <!-- Load Session -->
  <line x1="875" y1="220" x2="875" y2="180" stroke="#a78bfa" stroke-width="2" stroke-dasharray="5,5" marker-end="url(#arrowpurple)"/>
  <text x="920" y="200" fill="#fff" font-family="Arial" font-size="11">Load Context</text>

  <!-- Response 2 -->
  <line x1="790" y1="200" x2="210" y2="200" stroke="#10b981" stroke-width="2" stroke-dasharray="5,5"/>
  <text x="495" y="215" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">4. Response (working)</text>

  <!-- Turn 3: Final Input -->
  <line x1="200" y1="270" x2="790" y2="270" stroke="#3b82f6" stroke-width="2" marker-end="url(#arrowblue)"/>
  <text x="495" y="255" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">5. task-3 (session-abc) + confirmation</text>

  <!-- Update Session -->
  <line x1="875" y1="240" x2="875" y2="270" stroke="#a78bfa" stroke-width="2" marker-end="url(#arrowpurple)"/>
  <text x="905" y="255" fill="#fff" font-family="Arial" font-size="11">Update</text>

  <!-- Final Response -->
  <line x1="790" y1="350" x2="210" y2="350" stroke="#10b981" stroke-width="2" stroke-dasharray="5,5"/>
  <text x="495" y="335" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">6. Response (completed)</text>

  <!-- Conversation Flow Label -->
  <rect x="350" y="400" width="300" height="40" fill="none" stroke="#f59e0b" stroke-width="2" stroke-dasharray="5,5" rx="5"/>
  <text x="500" y="425" text-anchor="middle" fill="#fff" font-family="Arial" font-size="14" font-weight="bold">Multi-Turn Conversation</text>

  <!-- Arrow markers -->
  <defs>
    <marker id="arrowblue" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#3b82f6"/>
    </marker>
    <marker id="arrowgreen" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#10b981"/>
    </marker>
    <marker id="arroworange" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#f59e0b"/>
    </marker>
    <marker id="arrowpurple" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#a78bfa"/>
    </marker>
  </defs>
</svg>
```

### Flow Description

1. **Initial Request**: Client sends first task with new session ID
2. **Create Session**: Server initializes session context
3. **Agent Needs Input**: Returns task in `input-required` state
4. **Follow-up Request**: Client sends next task with same session ID and additional input
5. **Load Context**: Server retrieves session context from previous turns
6. **Process with Context**: Agent uses accumulated context to process request
7. **Update Session**: Session state updated with new information
8. **Complete**: Final response with `completed` state

## Session Lifecycle

### State Diagram

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 500" style="background:transparent">
  <!-- New Session -->
  <circle cx="400" cy="80" r="40" fill="#064e3b" stroke="#10b981" stroke-width="2"/>
  <text x="400" y="85" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12" font-weight="bold">New</text>
  <text x="400" y="140" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">sessionId assigned</text>

  <!-- Active Session -->
  <circle cx="400" cy="250" r="50" fill="#1e3a8a" stroke="#3b82f6" stroke-width="2"/>
  <text x="400" y="245" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12" font-weight="bold">Active</text>
  <text x="400" y="260" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">Multi-turn</text>
  <text x="400" y="275" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">conversation</text>

  <!-- Completed Session -->
  <circle cx="200" cy="420" r="40" fill="#065f46" stroke="#10b981" stroke-width="2"/>
  <text x="200" y="415" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12" font-weight="bold">Completed</text>
  <text x="200" y="430" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">Goal achieved</text>

  <!-- Expired Session -->
  <circle cx="600" cy="420" r="40" fill="#7f1d1d" stroke="#ef4444" stroke-width="2"/>
  <text x="600" y="415" text-anchor="middle" fill="#fff" font-family="Arial" font-size="12" font-weight="bold">Expired</text>
  <text x="600" y="430" text-anchor="middle" fill="#fff" font-family="Arial" font-size="11">Timeout/TTL</text>

  <!-- Transitions -->
  <line x1="400" y1="120" x2="400" y2="195" stroke="#10b981" stroke-width="2" marker-end="url(#arrowgreen)"/>
  <text x="430" y="160" fill="#fff" font-family="Arial" font-size="11">First task</text>

  <path d="M 350,280 Q 280,350 220,385" stroke="#10b981" stroke-width="2" fill="none" marker-end="url(#arrowgreen)"/>
  <text x="280" y="340" fill="#fff" font-family="Arial" font-size="11">Success</text>

  <path d="M 450,280 Q 520,350 580,385" stroke="#ef4444" stroke-width="2" fill="none" marker-end="url(#arrowred)"/>
  <text x="500" y="340" fill="#fff" font-family="Arial" font-size="11">Timeout</text>

  <!-- Self loop for active -->
  <path d="M 455,250 Q 500,250 500,280 Q 500,310 455,310" stroke="#3b82f6" stroke-width="2" fill="none" marker-end="url(#arrowblue)"/>
  <text x="510" y="280" fill="#fff" font-family="Arial" font-size="11">Continued turns</text>

  <!-- Arrow markers -->
  <defs>
    <marker id="arrowblue" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#3b82f6"/>
    </marker>
    <marker id="arrowgreen" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#10b981"/>
    </marker>
    <marker id="arrowred" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#ef4444"/>
    </marker>
  </defs>
</svg>
```

### Session States

1. **New**: Session created but no tasks processed yet
2. **Active**: Session has active ongoing conversation
3. **Completed**: All tasks in session completed successfully
4. **Expired**: Session timeout or TTL exceeded

## Implementation Guide

### Server-Side Session Management

#### Session Manager

```ruby
require 'a2a'

class SessionManager
  DEFAULT_TTL = 3600 # 1 hour

  def initialize(ttl: DEFAULT_TTL)
    @sessions = {} # sessionId => Session
    @ttl = ttl
    @cleanup_thread = start_cleanup_thread
  end

  # Get or create session
  def get_session(session_id)
    cleanup_expired_sessions

    @sessions[session_id] ||= Session.new(session_id, @ttl)
  end

  # Remove session
  def remove_session(session_id)
    @sessions.delete(session_id)
  end

  # Check if session exists
  def session_exists?(session_id)
    @sessions.key?(session_id) && !@sessions[session_id].expired?
  end

  # Get session stats
  def stats
    {
      total_sessions: @sessions.size,
      active_sessions: @sessions.count { |_, s| !s.expired? }
    }
  end

  private

  def cleanup_expired_sessions
    @sessions.delete_if { |_, session| session.expired? }
  end

  def start_cleanup_thread
    Thread.new do
      loop do
        sleep(60) # Run cleanup every minute
        cleanup_expired_sessions
      rescue StandardError => e
        debug_me "Cleanup error: #{e.message}"
      end
    end
  end
end

class Session
  attr_reader :id, :created_at, :updated_at, :context, :task_history

  def initialize(id, ttl)
    @id = id
    @ttl = ttl
    @created_at = Time.now
    @updated_at = Time.now
    @context = {}
    @task_history = []
  end

  # Add task to history
  def add_task(task, message)
    @task_history << {
      task_id: task.id,
      message: message,
      status: task.status,
      timestamp: Time.now
    }

    touch
  end

  # Update context
  def update_context(key, value)
    @context[key] = value
    touch
  end

  # Get context value
  def get_context(key)
    @context[key]
  end

  # Get all messages in conversation
  def get_messages
    @task_history.map { |entry| entry[:message] }
  end

  # Get last user message
  def get_last_user_message
    @task_history.reverse.find { |entry| entry[:message].role == 'user' }&.dig(:message)
  end

  # Get last agent message
  def get_last_agent_message
    @task_history.reverse.find { |entry| entry[:message].role == 'agent' }&.dig(:message)
  end

  # Check if expired
  def expired?
    Time.now - @updated_at > @ttl
  end

  # Get session age
  def age
    Time.now - @created_at
  end

  # Get turn count
  def turn_count
    @task_history.size
  end

  private

  def touch
    @updated_at = Time.now
  end
end
```

#### Server with Session Support

```ruby
require 'a2a'

class A2AConversationalServer < A2A::Server::Base
  def initialize(agent_card)
    super(agent_card)
    @session_manager = SessionManager.new(ttl: 3600)
    @task_store = {}
  end

  def handle_send_task(params)
    task = A2A::Models::Task.from_hash(params['task'] || params[:task])
    message = A2A::Models::Message.from_hash(params['message'] || params[:message])

    # Get or create session
    session = nil
    if task.session_id
      session = @session_manager.get_session(task.session_id)
      debug_me "Using existing session: #{task.session_id}"
    else
      debug_me "No session ID provided, processing as one-off task"
    end

    # Add to session history
    session&.add_task(task, message)

    # Process with context
    result_task = process_with_context(task, message, session)

    # Store task
    @task_store[result_task.id] = result_task

    result_task
  end

  def handle_get_task(params)
    task_id = params['taskId'] || params[:taskId]

    task = @task_store[task_id]
    raise A2A::TaskNotFoundError unless task

    task
  end

  private

  def process_with_context(task, message, session)
    # Extract user intent
    user_text = message.parts.find { |p| p.is_a?(A2A::Models::TextPart) }&.text

    if session
      # Multi-turn conversation logic
      process_multi_turn(task, message, session, user_text)
    else
      # Single turn logic
      process_single_turn(task, message, user_text)
    end
  end

  def process_multi_turn(task, message, session, user_text)
    # Get conversation history
    previous_messages = session.get_messages

    debug_me "Processing turn #{session.turn_count} in session #{session.id}"
    debug_me "Previous messages: #{previous_messages.size}"

    # Check if we have required context
    if session.get_context(:waiting_for_details) && session.get_context(:topic)
      # We asked for details and now have them
      topic = session.get_context(:topic)

      session.update_context(:waiting_for_details, false)
      session.update_context(:details_provided, user_text)

      # Generate complete response
      response_text = generate_detailed_response(topic, user_text, previous_messages)

      result_task = A2A::Models::Task.new(
        id: task.id,
        session_id: task.session_id,
        status: {
          state: 'completed',
          message: A2A::Models::Message.text(
            role: 'agent',
            text: response_text
          ),
          timestamp: Time.now.utc.iso8601
        },
        artifacts: [create_summary_artifact(session)],
        metadata: {
          session_turns: session.turn_count
        }
      )

      # Session complete, could clean up
      # @session_manager.remove_session(session.id)

      result_task

    elsif requires_more_info?(user_text)
      # Need to ask for clarification
      session.update_context(:topic, extract_topic(user_text))
      session.update_context(:waiting_for_details, true)

      A2A::Models::Task.new(
        id: task.id,
        session_id: task.session_id,
        status: {
          state: 'input-required',
          message: A2A::Models::Message.text(
            role: 'agent',
            text: "I'd be happy to help with that. Could you provide more details about what specifically you'd like to know?"
          ),
          timestamp: Time.now.utc.iso8601
        }
      )

    else
      # Can answer directly
      response_text = generate_response(user_text, previous_messages)

      A2A::Models::Task.new(
        id: task.id,
        session_id: task.session_id,
        status: {
          state: 'completed',
          message: A2A::Models::Message.text(
            role: 'agent',
            text: response_text
          ),
          timestamp: Time.now.utc.iso8601
        }
      )
    end
  end

  def process_single_turn(task, message, user_text)
    # Simple one-off processing
    response_text = generate_response(user_text, [])

    A2A::Models::Task.new(
      id: task.id,
      session_id: task.session_id,
      status: {
        state: 'completed',
        message: A2A::Models::Message.text(
          role: 'agent',
          text: response_text
        ),
        timestamp: Time.now.utc.iso8601
      }
    )
  end

  def requires_more_info?(text)
    # Simple heuristic - in practice use NLP
    text.length < 20 || text.split.size < 5
  end

  def extract_topic(text)
    # Extract main topic - simplified
    text.split.find { |word| word.length > 5 } || "general query"
  end

  def generate_response(text, context_messages)
    # Generate response using context
    context_summary = if context_messages.any?
      "Based on our previous conversation... "
    else
      ""
    end

    "#{context_summary}Here's information about: #{text}"
  end

  def generate_detailed_response(topic, details, context)
    "Great! Based on your question about #{topic} and the details you provided (#{details}), here's a comprehensive answer..."
  end

  def create_summary_artifact(session)
    A2A::Models::Artifact.new(
      name: "Conversation Summary",
      parts: [
        A2A::Models::DataPart.new(
          data: {
            session_id: session.id,
            turn_count: session.turn_count,
            duration: session.age.round(2),
            topics: session.context.keys.map(&:to_s)
          }
        )
      ]
    )
  end
end
```

### Client-Side Session Handling

#### Conversational Client

```ruby
require 'a2a'
require 'securerandom'

class A2AConversationalClient < A2A::Client::Base
  def initialize(agent_url)
    super(agent_url)
    @http_client = HTTP.timeout(connect: 5, write: 10, read: 10)
    @current_session = nil
  end

  # Start new conversation
  def start_conversation
    @current_session = ConversationSession.new
    debug_me "Started conversation: #{@current_session.id}"
    @current_session
  end

  # Send message in current conversation
  def send_message(text, session: nil)
    session ||= @current_session
    raise ArgumentError, "No active session" unless session

    message = A2A::Models::Message.text(role: 'user', text: text)

    task = send_task(
      task_id: "task-#{SecureRandom.uuid}",
      message: message,
      session_id: session.id
    )

    # Add to session history
    session.add_turn(message, task)

    task
  end

  # End conversation
  def end_conversation
    session = @current_session
    @current_session = nil
    debug_me "Ended conversation: #{session.id}"
    session
  end

  # Get current session
  def current_session
    @current_session
  end

  def send_task(task_id:, message:, session_id: nil)
    task = A2A::Models::Task.new(
      id: task_id,
      session_id: session_id,
      status: {
        state: 'submitted',
        timestamp: Time.now.utc.iso8601
      }
    )

    request = {
      jsonrpc: "2.0",
      id: task_id,
      method: "tasks/send",
      params: {
        task: task.to_h,
        message: message.to_h
      }
    }

    response = @http_client.post(
      agent_url,
      json: request,
      headers: { 'Content-Type' => 'application/json' }
    )

    unless response.status.success?
      raise A2A::InternalError, "HTTP #{response.status}: #{response.body}"
    end

    result = JSON.parse(response.body, symbolize_names: true)
    A2A::Models::Task.from_hash(result[:result])
  end
end

class ConversationSession
  attr_reader :id, :created_at, :turns

  def initialize
    @id = "session-#{SecureRandom.uuid}"
    @created_at = Time.now
    @turns = []
  end

  def add_turn(user_message, agent_response)
    @turns << {
      user: user_message,
      agent: agent_response,
      timestamp: Time.now
    }
  end

  def turn_count
    @turns.size
  end

  def get_context_messages
    messages = []
    @turns.each do |turn|
      messages << turn[:user]
      if turn[:agent].status.message
        messages << turn[:agent].status.message
      end
    end
    messages
  end

  def last_user_message
    @turns.last&.dig(:user)
  end

  def last_agent_response
    @turns.last&.dig(:agent)
  end
end
```

#### Using the Conversational Client

```ruby
# Interactive conversation example
client = A2AConversationalClient.new('https://api.example.com/a2a')

# Start conversation
session = client.start_conversation

# Turn 1
response1 = client.send_message("Tell me about machine learning")

if response1.status.state.value == 'input-required'
  # Agent needs more info
  agent_msg = response1.status.message.parts.first.text
  debug_me "Agent: #{agent_msg}"

  # Turn 2 - Provide details
  response2 = client.send_message(
    "I'm interested in supervised learning algorithms for classification",
    session: session
  )

  if response2.status.state.completed?
    agent_msg = response2.status.message.parts.first.text
    debug_me "Agent: #{agent_msg}"

    # Check for artifacts
    if response2.artifacts&.any?
      debug_me "Received #{response2.artifacts.size} artifacts"
    end
  end
end

# End conversation
final_session = client.end_conversation
debug_me "Conversation had #{final_session.turn_count} turns"
```

## Context Management

### Context Strategies

```ruby
class ContextManager
  def initialize
    @contexts = {}
  end

  # Store conversation context
  def set_context(session_id, key, value)
    @contexts[session_id] ||= {}
    @contexts[session_id][key] = {
      value: value,
      timestamp: Time.now
    }
  end

  # Get context value
  def get_context(session_id, key)
    @contexts.dig(session_id, key, :value)
  end

  # Get all context
  def get_all_context(session_id)
    @contexts[session_id]&.transform_values { |v| v[:value] } || {}
  end

  # Check if context exists
  def has_context?(session_id, key)
    @contexts.dig(session_id, key).present?
  end

  # Clear session context
  def clear_session(session_id)
    @contexts.delete(session_id)
  end

  # Get context age
  def context_age(session_id, key)
    timestamp = @contexts.dig(session_id, key, :timestamp)
    return nil unless timestamp

    Time.now - timestamp
  end
end
```

### Context Types

```ruby
module ContextTypes
  # User preferences
  class UserPreferences
    attr_accessor :language, :format, :verbosity

    def initialize
      @language = 'en'
      @format = 'text'
      @verbosity = 'normal'
    end
  end

  # Conversation state
  class ConversationState
    attr_accessor :current_topic, :subtopics_discussed, :pending_questions

    def initialize
      @current_topic = nil
      @subtopics_discussed = []
      @pending_questions = []
    end

    def add_subtopic(topic)
      @subtopics_discussed << topic unless @subtopics_discussed.include?(topic)
    end
  end

  # Task context
  class TaskContext
    attr_accessor :original_request, :refinements, :constraints

    def initialize(original_request)
      @original_request = original_request
      @refinements = []
      @constraints = {}
    end

    def add_refinement(refinement)
      @refinements << refinement
    end

    def add_constraint(key, value)
      @constraints[key] = value
    end
  end
end
```

## State Handling

### Managing Input-Required State

```ruby
class InputRequiredHandler
  def handle_input_required(task, session)
    # Extract what input is needed
    agent_message = task.status.message
    input_request = extract_input_request(agent_message)

    # Store what we're waiting for
    session.update_context(:awaiting_input, input_request)
    session.update_context(:awaiting_input_task_id, task.id)

    debug_me "Session #{session.id} now awaiting: #{input_request}"
  end

  def handle_input_provided(task, message, session)
    awaited_input = session.get_context(:awaiting_input)

    unless awaited_input
      debug_me "Warning: Received input but not awaiting any"
      return
    end

    # Extract provided input
    user_text = message.parts.find { |p| p.is_a?(A2A::Models::TextPart) }&.text

    # Store provided input
    session.update_context("provided_#{awaited_input}", user_text)
    session.update_context(:awaiting_input, nil)

    debug_me "Received awaited input: #{awaited_input} = #{user_text}"
  end

  private

  def extract_input_request(message)
    # Parse agent message to understand what's needed
    # This is simplified - real implementation would use NLP
    text = message.parts.first&.text || ""

    if text.include?("details")
      :details
    elsif text.include?("confirm")
      :confirmation
    elsif text.include?("choose") || text.include?("select")
      :choice
    else
      :general_input
    end
  end
end
```

### State Persistence

```ruby
require 'json'

class PersistentSessionManager < SessionManager
  def initialize(storage_path: './sessions', ttl: 3600)
    super(ttl: ttl)
    @storage_path = storage_path
    FileUtils.mkdir_p(@storage_path)
    load_sessions
  end

  def get_session(session_id)
    unless @sessions[session_id]
      # Try to load from disk
      loaded = load_session_from_disk(session_id)
      @sessions[session_id] = loaded if loaded
    end

    super
  end

  def save_session(session)
    File.write(
      session_file_path(session.id),
      serialize_session(session)
    )
  end

  private

  def load_sessions
    return unless Dir.exist?(@storage_path)

    Dir.glob(File.join(@storage_path, '*.json')).each do |file|
      begin
        data = JSON.parse(File.read(file), symbolize_names: true)
        session = deserialize_session(data)
        @sessions[session.id] = session unless session.expired?
      rescue StandardError => e
        debug_me "Failed to load session from #{file}: #{e.message}"
      end
    end

    debug_me "Loaded #{@sessions.size} sessions from disk"
  end

  def load_session_from_disk(session_id)
    file_path = session_file_path(session_id)
    return nil unless File.exist?(file_path)

    data = JSON.parse(File.read(file_path), symbolize_names: true)
    deserialize_session(data)
  rescue StandardError => e
    debug_me "Failed to load session #{session_id}: #{e.message}"
    nil
  end

  def session_file_path(session_id)
    File.join(@storage_path, "#{session_id}.json")
  end

  def serialize_session(session)
    JSON.pretty_generate({
      id: session.id,
      created_at: session.created_at.iso8601,
      updated_at: session.updated_at.iso8601,
      context: session.context,
      task_history: session.task_history.map { |entry|
        {
          task_id: entry[:task_id],
          message: entry[:message].to_h,
          status: entry[:status].to_h,
          timestamp: entry[:timestamp].iso8601
        }
      }
    })
  end

  def deserialize_session(data)
    session = Session.new(data[:id], @ttl)
    session.instance_variable_set(:@created_at, Time.parse(data[:created_at]))
    session.instance_variable_set(:@updated_at, Time.parse(data[:updated_at]))
    session.instance_variable_set(:@context, data[:context])

    task_history = data[:task_history].map do |entry|
      {
        task_id: entry[:task_id],
        message: A2A::Models::Message.from_hash(entry[:message]),
        status: A2A::Models::TaskStatus.from_hash(entry[:status]),
        timestamp: Time.parse(entry[:timestamp])
      }
    end
    session.instance_variable_set(:@task_history, task_history)

    session
  end
end
```

## Best Practices

### 1. Always Include Session ID for Multi-Turn

```ruby
def send_followup_message(text, previous_task)
  # Reuse session ID from previous task
  send_task(
    task_id: "task-#{SecureRandom.uuid}",
    message: A2A::Models::Message.text(role: 'user', text: text),
    session_id: previous_task.session_id  # Important!
  )
end
```

### 2. Set Appropriate Session TTL

```ruby
# Short conversations (chatbot)
short_session_manager = SessionManager.new(ttl: 900) # 15 minutes

# Long conversations (research assistant)
long_session_manager = SessionManager.new(ttl: 7200) # 2 hours

# Extended workflows (multi-day projects)
extended_session_manager = SessionManager.new(ttl: 86400) # 24 hours
```

### 3. Clean Up Context

```ruby
class Session
  def cleanup_old_context(max_age: 3600)
    @context.delete_if do |key, value|
      if value.is_a?(Hash) && value[:timestamp]
        Time.now - value[:timestamp] > max_age
      else
        false
      end
    end
  end
end
```

### 4. Limit History Size

```ruby
class Session
  MAX_HISTORY = 50

  def add_task(task, message)
    @task_history << {
      task_id: task.id,
      message: message,
      status: task.status,
      timestamp: Time.now
    }

    # Keep only recent history
    @task_history = @task_history.last(MAX_HISTORY) if @task_history.size > MAX_HISTORY

    touch
  end
end
```

### 5. Handle Session Expiration Gracefully

```ruby
def get_session_safe(session_id)
  session = @session_manager.get_session(session_id)

  if session.expired?
    debug_me "Session #{session_id} expired, creating new one"
    @session_manager.remove_session(session_id)
    session = @session_manager.get_session(session_id)
  end

  session
end
```

## Complete Examples

### Multi-Step Form Workflow

```ruby
class FormWorkflowServer < A2AConversationalServer
  FORM_FIELDS = %i[name email phone_number address preferences]

  def process_multi_turn(task, message, session, user_text)
    # Check form completion status
    completed_fields = session.get_context(:completed_fields) || []
    current_field = session.get_context(:current_field)

    if current_field
      # Save provided value
      session.update_context(current_field, user_text)
      completed_fields << current_field
      session.update_context(:completed_fields, completed_fields)
    end

    # Find next required field
    next_field = FORM_FIELDS.find { |f| !completed_fields.include?(f) }

    if next_field
      # Ask for next field
      session.update_context(:current_field, next_field)

      prompt = generate_field_prompt(next_field)

      A2A::Models::Task.new(
        id: task.id,
        session_id: task.session_id,
        status: {
          state: 'input-required',
          message: A2A::Models::Message.text(role: 'agent', text: prompt),
          timestamp: Time.now.utc.iso8601
        },
        metadata: {
          progress: "#{completed_fields.size}/#{FORM_FIELDS.size}"
        }
      )
    else
      # Form complete
      form_data = FORM_FIELDS.each_with_object({}) do |field, hash|
        hash[field] = session.get_context(field)
      end

      artifact = A2A::Models::Artifact.new(
        name: "Completed Form",
        parts: [
          A2A::Models::DataPart.new(data: form_data)
        ]
      )

      A2A::Models::Task.new(
        id: task.id,
        session_id: task.session_id,
        status: {
          state: 'completed',
          message: A2A::Models::Message.text(
            role: 'agent',
            text: "Thank you! Your form has been completed."
          ),
          timestamp: Time.now.utc.iso8601
        },
        artifacts: [artifact]
      )
    end
  end

  private

  def generate_field_prompt(field)
    prompts = {
      name: "What is your full name?",
      email: "What is your email address?",
      phone_number: "What is your phone number?",
      address: "What is your mailing address?",
      preferences: "What are your preferences?"
    }

    prompts[field]
  end
end
```

### Interactive Tutorial Agent

```ruby
class TutorialAgent
  def initialize(session_manager)
    @session_manager = session_manager
    @lessons = load_lessons
  end

  def process_message(task, message, session)
    user_text = extract_text(message)

    # Check lesson progress
    current_lesson = session.get_context(:current_lesson) || 0
    lesson_step = session.get_context(:lesson_step) || 0

    lesson = @lessons[current_lesson]

    if user_text.downcase.include?('next')
      # Move to next step
      lesson_step += 1

      if lesson_step >= lesson[:steps].size
        # Lesson complete
        current_lesson += 1
        lesson_step = 0

        if current_lesson >= @lessons.size
          # Tutorial complete!
          return create_completion_task(task, session)
        end

        lesson = @lessons[current_lesson]
      end

      session.update_context(:current_lesson, current_lesson)
      session.update_context(:lesson_step, lesson_step)

      create_lesson_task(task, session, lesson, lesson_step)

    elsif user_text.downcase.include?('help')
      # Provide hint
      create_hint_task(task, lesson, lesson_step)

    elsif user_text.downcase.include?('repeat')
      # Repeat current step
      create_lesson_task(task, session, lesson, lesson_step)

    else
      # Validate answer
      if validate_answer(user_text, lesson, lesson_step)
        session.update_context(:lesson_step, lesson_step + 1)
        create_correct_answer_task(task, session, lesson)
      else
        create_incorrect_answer_task(task, lesson, lesson_step)
      end
    end
  end

  private

  def load_lessons
    [
      {
        title: "Introduction to A2A",
        steps: [
          "What does A2A stand for? (type your answer)",
          "Name one capability an agent can have",
          "What is a Task in A2A?"
        ],
        answers: [
          ["agent2agent", "agent to agent"],
          ["streaming", "push notifications", "state transition history"],
          ["unit of work", "central unit"]
        ]
      }
      # ... more lessons
    ]
  end

  def validate_answer(text, lesson, step)
    correct_answers = lesson[:answers][step] || []
    correct_answers.any? { |answer| text.downcase.include?(answer.downcase) }
  end

  def create_lesson_task(task, session, lesson, step)
    progress = "Lesson #{session.get_context(:current_lesson) + 1}/#{@lessons.size}, Step #{step + 1}/#{lesson[:steps].size}"

    A2A::Models::Task.new(
      id: task.id,
      session_id: task.session_id,
      status: {
        state: 'input-required',
        message: A2A::Models::Message.text(
          role: 'agent',
          text: "#{progress}\n\n#{lesson[:steps][step]}\n\n(type 'help' for a hint, 'next' to skip)"
        ),
        timestamp: Time.now.utc.iso8601
      }
    )
  end

  def create_completion_task(task, session)
    A2A::Models::Task.new(
      id: task.id,
      session_id: task.session_id,
      status: {
        state: 'completed',
        message: A2A::Models::Message.text(
          role: 'agent',
          text: "Congratulations! You've completed the A2A tutorial!"
        ),
        timestamp: Time.now.utc.iso8601
      },
      artifacts: [
        A2A::Models::Artifact.new(
          name: "Tutorial Certificate",
          parts: [
            A2A::Models::DataPart.new(
              data: {
                session_id: session.id,
                completed_at: Time.now.iso8601,
                lessons_completed: @lessons.size
              }
            )
          ]
        )
      ]
    )
  end

  # Additional helper methods...
end
```

## Testing Strategies

### Unit Testing Sessions

```ruby
RSpec.describe SessionManager do
  let(:manager) { SessionManager.new(ttl: 60) }

  describe '#get_session' do
    it 'creates new session if not exists' do
      session = manager.get_session('session-1')

      expect(session).to be_a(Session)
      expect(session.id).to eq('session-1')
    end

    it 'returns existing session' do
      session1 = manager.get_session('session-1')
      session2 = manager.get_session('session-1')

      expect(session1).to eq(session2)
    end
  end

  describe 'session expiration' do
    it 'removes expired sessions' do
      session = manager.get_session('session-1')

      # Simulate time passage
      allow(Time).to receive(:now).and_return(Time.now + 120)

      expect(session.expired?).to be true
      expect(manager.session_exists?('session-1')).to be false
    end
  end
end
```

### Integration Testing Conversations

```ruby
RSpec.describe 'Multi-turn conversation' do
  let(:client) { A2AConversationalClient.new('https://api.test/a2a') }

  it 'maintains context across turns' do
    stub_requests

    session = client.start_conversation

    # Turn 1
    response1 = client.send_message("Hello", session: session)
    expect(response1.session_id).to eq(session.id)

    # Turn 2 - same session
    response2 = client.send_message("Tell me more", session: session)
    expect(response2.session_id).to eq(session.id)

    expect(session.turn_count).to eq(2)
  end

  def stub_requests
    stub_request(:post, 'https://api.test/a2a')
      .to_return(status: 200, body: mock_response.to_json)
  end
end
```

## Troubleshooting

### Issue: Session Not Found

**Solution**: Check session expiration and implement graceful degradation

```ruby
def handle_send_task(params)
  task = A2A::Models::Task.from_hash(params['task'])

  if task.session_id && !@session_manager.session_exists?(task.session_id)
    debug_me "Session #{task.session_id} not found or expired"

    # Option 1: Create new session with same ID
    session = @session_manager.get_session(task.session_id)

    # Option 2: Return error
    # raise A2A::InvalidParamsError, "Session expired or not found"

    # Option 3: Process without context
    # session = nil
  end

  # Process normally
end
```

### Issue: Context Growing Too Large

**Solution**: Implement context pruning

```ruby
class Session
  MAX_CONTEXT_SIZE = 1000 # bytes

  def update_context(key, value)
    @context[key] = value

    # Check size
    prune_context_if_needed
    touch
  end

  private

  def prune_context_if_needed
    size = estimate_context_size

    if size > MAX_CONTEXT_SIZE
      # Remove oldest non-critical context
      prune_old_context
    end
  end

  def estimate_context_size
    @context.to_json.bytesize
  end

  def prune_old_context
    # Keep only essential context
    essential_keys = [:current_state, :user_id, :topic]
    @context = @context.slice(*essential_keys)
  end
end
```

---

## Related Documentation

- [Streaming](streaming.md) - Using sessions with streaming
- [Push Notifications](push-notifications.md) - Async updates in conversations
- [Task Lifecycle](../guides/tasks.md) - Understanding task states
- [Messages](../guides/messages.md) - Message structure and roles

## Further Reading

- [A2A Protocol Specification](../protocol-spec.md)
- [Conversation Design Best Practices](https://www.nngroup.com/articles/chatbot-usability/)
- [Session Management Patterns](https://martinfowler.com/articles/session-state.html)
