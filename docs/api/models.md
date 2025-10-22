# Models API Reference

Complete reference for all model classes in the A2A gem (`A2A::Models` namespace).

## Overview

The Models layer provides data structures representing all entities in the A2A protocol. All models support JSON serialization and deserialization for protocol communication.

## Table of Contents

- [Task Management](#task-management)
  - [Task](#task)
  - [TaskStatus](#taskstatus)
  - [TaskState](#taskstate)
- [Communication](#communication)
  - [Message](#message)
  - [Artifact](#artifact)
- [Parts](#parts)
  - [Part](#part-base-class)
  - [TextPart](#textpart)
  - [FilePart](#filepart)
  - [DataPart](#datapart)
  - [FileContent](#filecontent)
- [Agent Metadata](#agent-metadata)
  - [AgentCard](#agentcard)
  - [AgentCapabilities](#agentcapabilities)
  - [AgentSkill](#agentskill)
  - [AgentProvider](#agentprovider)
  - [AgentAuthentication](#agentauthentication)
- [Configuration](#configuration)
  - [PushNotificationConfig](#pushnotificationconfig)

---

## Task Management

### Task

Represents a task in the A2A protocol - the central unit of work with a unique ID that progresses through various states.

**Source:** `lib/a2a/models/task.rb`

#### Constructor

```ruby
A2A::Models::Task.new(
  id:,
  status:,
  session_id: nil,
  artifacts: nil,
  metadata: nil
)
```

**Parameters:**

- `id` (String, required) - Unique task identifier
- `status` (TaskStatus or Hash, required) - Task status object or hash
- `session_id` (String, optional) - Session identifier for multi-turn conversations
- `artifacts` (Array<Artifact>, optional) - Array of artifacts produced by the task
- `metadata` (Hash, optional) - Additional metadata

**Returns:** `Task` instance

**Example:**

```ruby
task = A2A::Models::Task.new(
  id: SecureRandom.uuid,
  status: A2A::Models::TaskStatus.new(state: 'submitted'),
  session_id: 'session-abc-123',
  artifacts: [],
  metadata: { priority: 'high' }
)
```

#### Instance Methods

##### `#id`

Returns the unique task identifier.

**Returns:** `String`

##### `#session_id`

Returns the session identifier.

**Returns:** `String` or `nil`

##### `#status`

Returns the task status.

**Returns:** `TaskStatus`

##### `#state`

Returns the current state of the task (convenience method).

**Returns:** `TaskState`

```ruby
task.state  # => #<A2A::Models::TaskState:... @value="submitted">
```

##### `#artifacts`

Returns the array of artifacts.

**Returns:** `Array<Artifact>` or `nil`

##### `#metadata`

Returns additional metadata.

**Returns:** `Hash` or `nil`

##### `#to_h`

Converts the task to a hash representation.

**Returns:** `Hash`

```ruby
task.to_h
# => {
#   id: "task-123",
#   sessionId: "session-abc",
#   status: { state: "submitted", timestamp: "2025-01-15T10:30:00Z" },
#   artifacts: [...],
#   metadata: { ... }
# }
```

##### `#to_json(*args)`

Converts the task to a JSON string.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates a Task instance from a hash.

**Parameters:**

- `hash` (Hash) - Hash representation (supports both symbol and string keys)

**Returns:** `Task`

**Example:**

```ruby
task = A2A::Models::Task.from_hash({
  'id' => 'task-456',
  'status' => { 'state' => 'working' }
})
```

---

### TaskStatus

Represents the status of a task, including its state, optional message, and timestamp.

**Source:** `lib/a2a/models/task_status.rb`

#### Constructor

```ruby
A2A::Models::TaskStatus.new(
  state:,
  message: nil,
  timestamp: nil
)
```

**Parameters:**

- `state` (TaskState, String, required) - Task state (will be converted to TaskState if string)
- `message` (Message, Hash, optional) - Optional message providing context
- `timestamp` (String, optional) - ISO8601 timestamp (defaults to current UTC time)

**Returns:** `TaskStatus` instance

**Example:**

```ruby
status = A2A::Models::TaskStatus.new(
  state: 'working',
  message: A2A::Models::Message.text(role: 'agent', text: 'Processing your request...'),
  timestamp: Time.now.utc.iso8601
)
```

#### Instance Methods

##### `#state`

Returns the task state.

**Returns:** `TaskState`

##### `#message`

Returns the optional status message.

**Returns:** `Message` or `nil`

##### `#timestamp`

Returns the ISO8601 timestamp.

**Returns:** `String`

##### `#to_h`

Converts the status to a hash.

**Returns:** `Hash`

##### `#to_json(*args)`

Converts the status to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates a TaskStatus from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `TaskStatus`

---

### TaskState

Represents the state of a task with validation and convenience methods.

**Source:** `lib/a2a/models/task_state.rb`

#### Valid States

- `submitted` - Task has been submitted
- `working` - Task is being processed
- `input-required` - Task requires additional input
- `completed` - Task has completed successfully
- `canceled` - Task was canceled
- `failed` - Task failed
- `unknown` - State is unknown

#### Constructor

```ruby
A2A::Models::TaskState.new(value)
```

**Parameters:**

- `value` (String, required) - State value (must be one of the valid states)

**Raises:** `ArgumentError` if value is not a valid state

**Returns:** `TaskState` instance

**Example:**

```ruby
state = A2A::Models::TaskState.new('working')
```

#### Instance Methods

##### `#value`

Returns the state value.

**Returns:** `String`

##### `#to_s`

Returns the state as a string.

**Returns:** `String`

##### `#to_json(*args)`

Returns the state as JSON.

**Returns:** `String`

##### `#==(other)`

Compares two TaskState objects.

**Returns:** `Boolean`

##### State Check Methods

All return `Boolean`:

- `#submitted?` - Returns true if state is 'submitted'
- `#working?` - Returns true if state is 'working'
- `#input_required?` - Returns true if state is 'input-required'
- `#completed?` - Returns true if state is 'completed'
- `#canceled?` - Returns true if state is 'canceled'
- `#failed?` - Returns true if state is 'failed'
- `#unknown?` - Returns true if state is 'unknown'
- `#terminal?` - Returns true if state is completed, canceled, or failed

**Example:**

```ruby
state = A2A::Models::TaskState.new('completed')
state.completed?  # => true
state.terminal?   # => true
state.working?    # => false
```

---

## Communication

### Message

Represents communication turns between the client (role: "user") and the agent (role: "agent"). Messages contain Parts.

**Source:** `lib/a2a/models/message.rb`

#### Valid Roles

- `user` - Message from the user/client
- `agent` - Message from the agent

#### Constructor

```ruby
A2A::Models::Message.new(
  role:,
  parts:,
  metadata: nil
)
```

**Parameters:**

- `role` (String, required) - Message role ('user' or 'agent')
- `parts` (Array<Part>, required) - Array of message parts
- `metadata` (Hash, optional) - Additional metadata

**Raises:** `ArgumentError` if role is invalid

**Returns:** `Message` instance

**Example:**

```ruby
message = A2A::Models::Message.new(
  role: 'user',
  parts: [
    A2A::Models::TextPart.new(text: 'Hello!'),
    A2A::Models::TextPart.new(text: 'How are you?')
  ]
)
```

#### Instance Methods

##### `#role`

Returns the message role.

**Returns:** `String`

##### `#parts`

Returns the array of parts.

**Returns:** `Array<Part>`

##### `#metadata`

Returns optional metadata.

**Returns:** `Hash` or `nil`

##### `#to_h`

Converts to hash.

**Returns:** `Hash`

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates a Message from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `Message`

##### `.text(role:, text:, metadata: nil)`

Convenience constructor for simple text messages.

**Parameters:**

- `role` (String, required) - Message role
- `text` (String, required) - Text content
- `metadata` (Hash, optional) - Additional metadata

**Returns:** `Message`

**Example:**

```ruby
message = A2A::Models::Message.text(
  role: 'user',
  text: 'Analyze this data for trends.'
)
```

---

### Artifact

Represents outputs generated by the agent during a task. Artifacts contain Parts (text, file, or data).

**Source:** `lib/a2a/models/artifact.rb`

#### Constructor

```ruby
A2A::Models::Artifact.new(
  parts:,
  name: nil,
  description: nil,
  index: 0,
  append: nil,
  last_chunk: nil,
  metadata: nil
)
```

**Parameters:**

- `parts` (Array<Part>, required) - Array of artifact parts
- `name` (String, optional) - Artifact name
- `description` (String, optional) - Artifact description
- `index` (Integer, optional) - Artifact index (default: 0)
- `append` (Boolean, optional) - Whether to append to existing artifact
- `last_chunk` (Boolean, optional) - Indicates if this is the last chunk in streaming
- `metadata` (Hash, optional) - Additional metadata

**Returns:** `Artifact` instance

**Example:**

```ruby
artifact = A2A::Models::Artifact.new(
  name: 'analysis-report',
  description: 'Comprehensive data analysis',
  parts: [
    A2A::Models::TextPart.new(text: '## Summary\n\nAnalysis complete.'),
    A2A::Models::DataPart.new(data: { total_records: 1000, errors: 5 })
  ],
  index: 0
)
```

#### Instance Methods

##### `#name`

Returns the artifact name.

**Returns:** `String` or `nil`

##### `#description`

Returns the artifact description.

**Returns:** `String` or `nil`

##### `#parts`

Returns the array of parts.

**Returns:** `Array<Part>`

##### `#index`

Returns the artifact index.

**Returns:** `Integer`

##### `#append`

Returns the append flag.

**Returns:** `Boolean` or `nil`

##### `#last_chunk`

Returns whether this is the last chunk.

**Returns:** `Boolean` or `nil`

##### `#metadata`

Returns metadata.

**Returns:** `Hash` or `nil`

##### `#to_h`

Converts to hash (uses camelCase for JSON keys).

**Returns:** `Hash`

```ruby
artifact.to_h
# => {
#   name: "report",
#   description: "...",
#   parts: [...],
#   index: 0,
#   lastChunk: true
# }
```

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates an Artifact from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `Artifact`

---

## Parts

### Part (Base Class)

Base class for message and artifact parts. Parts can be TextPart, FilePart, or DataPart.

**Source:** `lib/a2a/models/part.rb`

#### Constructor

```ruby
A2A::Models::Part.new(metadata: nil)
```

**Parameters:**

- `metadata` (Hash, optional) - Part metadata

**Note:** This is an abstract base class. Use subclasses instead.

#### Instance Methods

##### `#metadata`

Returns part metadata.

**Returns:** `Hash` or `nil`

##### `#type`

Returns the part type.

**Returns:** `String`

**Raises:** `NotImplementedError` (must be implemented by subclasses)

##### `#to_h`

Converts to hash.

**Returns:** `Hash`

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Factory method to create the appropriate Part subclass from a hash.

**Parameters:**

- `hash` (Hash) - Must include 'type' key ('text', 'file', or 'data')

**Returns:** `TextPart`, `FilePart`, or `DataPart`

**Raises:** `ArgumentError` if type is unknown

**Example:**

```ruby
part = A2A::Models::Part.from_hash({ type: 'text', text: 'Hello!' })
# => #<A2A::Models::TextPart:...>
```

---

### TextPart

Represents a text part in a message or artifact.

**Source:** `lib/a2a/models/text_part.rb`

#### Constructor

```ruby
A2A::Models::TextPart.new(text:, metadata: nil)
```

**Parameters:**

- `text` (String, required) - Text content
- `metadata` (Hash, optional) - Part metadata

**Returns:** `TextPart` instance

**Example:**

```ruby
part = A2A::Models::TextPart.new(
  text: 'This is the text content.',
  metadata: { language: 'en' }
)
```

#### Instance Methods

##### `#text`

Returns the text content.

**Returns:** `String`

##### `#type`

Returns 'text'.

**Returns:** `String`

##### `#metadata`

Returns metadata (inherited from Part).

**Returns:** `Hash` or `nil`

##### `#to_h`

Converts to hash.

**Returns:** `Hash`

```ruby
part.to_h
# => { type: 'text', text: 'content', metadata: {...} }
```

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates a TextPart from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `TextPart`

---

### FilePart

Represents a file part in a message or artifact.

**Source:** `lib/a2a/models/file_part.rb`

#### Constructor

```ruby
A2A::Models::FilePart.new(file:, metadata: nil)
```

**Parameters:**

- `file` (FileContent or Hash, required) - File content object or hash
- `metadata` (Hash, optional) - Part metadata

**Returns:** `FilePart` instance

**Example:**

```ruby
part = A2A::Models::FilePart.new(
  file: {
    name: 'report.pdf',
    mime_type: 'application/pdf',
    bytes: Base64.strict_encode64(file_data)
  }
)
```

#### Instance Methods

##### `#file`

Returns the file content.

**Returns:** `FileContent`

##### `#type`

Returns 'file'.

**Returns:** `String`

##### `#metadata`

Returns metadata.

**Returns:** `Hash` or `nil`

##### `#to_h`

Converts to hash.

**Returns:** `Hash`

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates a FilePart from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `FilePart`

---

### DataPart

Represents a structured data part in a message or artifact. Used for forms and other structured JSON data.

**Source:** `lib/a2a/models/data_part.rb`

#### Constructor

```ruby
A2A::Models::DataPart.new(data:, metadata: nil)
```

**Parameters:**

- `data` (Hash or Array, required) - Structured data
- `metadata` (Hash, optional) - Part metadata

**Returns:** `DataPart` instance

**Example:**

```ruby
part = A2A::Models::DataPart.new(
  data: {
    form: {
      name: 'John Doe',
      email: 'john@example.com',
      preferences: ['email', 'sms']
    }
  }
)
```

#### Instance Methods

##### `#data`

Returns the structured data.

**Returns:** `Hash` or `Array`

##### `#type`

Returns 'data'.

**Returns:** `String`

##### `#metadata`

Returns metadata.

**Returns:** `Hash` or `nil`

##### `#to_h`

Converts to hash.

**Returns:** `Hash`

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates a DataPart from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `DataPart`

---

### FileContent

Represents the content of a file, either as base64 encoded bytes or a URI. Ensures that either 'bytes' or 'uri' is provided, but not both.

**Source:** `lib/a2a/models/file_content.rb`

#### Constructor

```ruby
A2A::Models::FileContent.new(
  name: nil,
  mime_type: nil,
  bytes: nil,
  uri: nil
)
```

**Parameters:**

- `name` (String, optional) - File name
- `mime_type` (String, optional) - MIME type
- `bytes` (String, optional) - Base64 encoded file content
- `uri` (String, optional) - URI to the file

**Raises:** `ArgumentError` if:
  - Neither bytes nor uri is provided
  - Both bytes and uri are provided

**Returns:** `FileContent` instance

**Example:**

```ruby
# Using bytes
file = A2A::Models::FileContent.new(
  name: 'data.csv',
  mime_type: 'text/csv',
  bytes: Base64.strict_encode64(csv_data)
)

# Using URI
file = A2A::Models::FileContent.new(
  name: 'image.png',
  mime_type: 'image/png',
  uri: 'https://example.com/image.png'
)
```

#### Instance Methods

##### `#name`

Returns the file name.

**Returns:** `String` or `nil`

##### `#mime_type`

Returns the MIME type.

**Returns:** `String` or `nil`

##### `#bytes`

Returns the base64 encoded bytes.

**Returns:** `String` or `nil`

##### `#uri`

Returns the file URI.

**Returns:** `String` or `nil`

##### `#to_h`

Converts to hash (uses camelCase for JSON).

**Returns:** `Hash`

```ruby
file.to_h
# => { name: 'file.txt', mimeType: 'text/plain', bytes: '...' }
```

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates a FileContent from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `FileContent`

---

## Agent Metadata

### AgentCard

Represents an agent's metadata and capabilities. Usually served at `/.well-known/agent.json`.

**Source:** `lib/a2a/models/agent_card.rb`

#### Constructor

```ruby
A2A::Models::AgentCard.new(
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
```

**Parameters:**

- `name` (String, required) - Agent name
- `url` (String, required) - Agent URL
- `version` (String, required) - Agent version
- `capabilities` (AgentCapabilities or Hash, required) - Agent capabilities
- `skills` (Array<AgentSkill> or Array<Hash>, required) - Agent skills
- `description` (String, optional) - Agent description
- `provider` (AgentProvider or Hash, optional) - Provider information
- `documentation_url` (String, optional) - Documentation URL
- `authentication` (AgentAuthentication or Hash, optional) - Authentication config
- `default_input_modes` (Array<String>, optional) - Default input modes (default: ['text'])
- `default_output_modes` (Array<String>, optional) - Default output modes (default: ['text'])

**Returns:** `AgentCard` instance

**Example:**

```ruby
card = A2A::Models::AgentCard.new(
  name: 'DataAnalyzer',
  description: 'AI-powered data analysis agent',
  url: 'https://agents.example.com/analyzer',
  version: '1.0.0',
  provider: {
    organization: 'Example Corp',
    url: 'https://example.com'
  },
  documentation_url: 'https://docs.example.com/analyzer',
  capabilities: {
    streaming: true,
    push_notifications: false,
    state_transition_history: true
  },
  authentication: {
    schemes: ['bearer'],
    credentials: 'https://auth.example.com'
  },
  default_input_modes: ['text', 'file'],
  default_output_modes: ['text', 'data'],
  skills: [
    {
      id: 'data-analysis',
      name: 'Data Analysis',
      description: 'Analyze CSV and Excel files',
      tags: ['analytics', 'data'],
      input_modes: ['file'],
      output_modes: ['text', 'data']
    }
  ]
)
```

#### Instance Methods

##### `#name`

Returns the agent name.

**Returns:** `String`

##### `#description`

Returns the agent description.

**Returns:** `String` or `nil`

##### `#url`

Returns the agent URL.

**Returns:** `String`

##### `#provider`

Returns the provider information.

**Returns:** `AgentProvider` or `nil`

##### `#version`

Returns the agent version.

**Returns:** `String`

##### `#documentation_url`

Returns the documentation URL.

**Returns:** `String` or `nil`

##### `#capabilities`

Returns the agent capabilities.

**Returns:** `AgentCapabilities`

##### `#authentication`

Returns the authentication configuration.

**Returns:** `AgentAuthentication` or `nil`

##### `#default_input_modes`

Returns the default input modes.

**Returns:** `Array<String>`

##### `#default_output_modes`

Returns the default output modes.

**Returns:** `Array<String>`

##### `#skills`

Returns the agent skills.

**Returns:** `Array<AgentSkill>`

##### `#to_h`

Converts to hash (uses camelCase).

**Returns:** `Hash`

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates an AgentCard from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `AgentCard`

---

### AgentCapabilities

Represents the capabilities supported by an agent.

**Source:** `lib/a2a/models/agent_capabilities.rb`

#### Constructor

```ruby
A2A::Models::AgentCapabilities.new(
  streaming: false,
  push_notifications: false,
  state_transition_history: false
)
```

**Parameters:**

- `streaming` (Boolean, optional) - Supports streaming (default: false)
- `push_notifications` (Boolean, optional) - Supports push notifications (default: false)
- `state_transition_history` (Boolean, optional) - Supports state history (default: false)

**Returns:** `AgentCapabilities` instance

**Example:**

```ruby
caps = A2A::Models::AgentCapabilities.new(
  streaming: true,
  push_notifications: false,
  state_transition_history: true
)
```

#### Instance Methods

##### `#streaming`

Returns the streaming capability.

**Returns:** `Boolean`

##### `#streaming?`

Returns whether streaming is supported.

**Returns:** `Boolean`

##### `#push_notifications`

Returns the push notifications capability.

**Returns:** `Boolean`

##### `#push_notifications?`

Returns whether push notifications are supported.

**Returns:** `Boolean`

##### `#state_transition_history`

Returns the state transition history capability.

**Returns:** `Boolean`

##### `#state_transition_history?`

Returns whether state transition history is supported.

**Returns:** `Boolean`

##### `#to_h`

Converts to hash (uses camelCase).

**Returns:** `Hash`

```ruby
caps.to_h
# => { streaming: true, pushNotifications: false, stateTransitionHistory: true }
```

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates AgentCapabilities from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `AgentCapabilities`

---

### AgentSkill

Represents a skill that an agent can perform.

**Source:** `lib/a2a/models/agent_skill.rb`

#### Constructor

```ruby
A2A::Models::AgentSkill.new(
  id:,
  name:,
  description: nil,
  tags: nil,
  examples: nil,
  input_modes: nil,
  output_modes: nil
)
```

**Parameters:**

- `id` (String, required) - Unique skill identifier
- `name` (String, required) - Skill name
- `description` (String, optional) - Skill description
- `tags` (Array<String>, optional) - Skill tags
- `examples` (Array<String>, optional) - Example uses
- `input_modes` (Array<String>, optional) - Supported input modes
- `output_modes` (Array<String>, optional) - Supported output modes

**Returns:** `AgentSkill` instance

**Example:**

```ruby
skill = A2A::Models::AgentSkill.new(
  id: 'code-review',
  name: 'Code Review',
  description: 'Review code for best practices and potential issues',
  tags: ['development', 'quality'],
  examples: ['Review my Python code', 'Check this JavaScript for bugs'],
  input_modes: ['text', 'file'],
  output_modes: ['text', 'data']
)
```

#### Instance Methods

##### `#id`

Returns the skill ID.

**Returns:** `String`

##### `#name`

Returns the skill name.

**Returns:** `String`

##### `#description`

Returns the skill description.

**Returns:** `String` or `nil`

##### `#tags`

Returns the skill tags.

**Returns:** `Array<String>` or `nil`

##### `#examples`

Returns example uses.

**Returns:** `Array<String>` or `nil`

##### `#input_modes`

Returns supported input modes.

**Returns:** `Array<String>` or `nil`

##### `#output_modes`

Returns supported output modes.

**Returns:** `Array<String>` or `nil`

##### `#to_h`

Converts to hash (uses camelCase).

**Returns:** `Hash`

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates an AgentSkill from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `AgentSkill`

---

### AgentProvider

Represents the provider information for an agent.

**Source:** `lib/a2a/models/agent_provider.rb`

#### Constructor

```ruby
A2A::Models::AgentProvider.new(
  organization:,
  url: nil
)
```

**Parameters:**

- `organization` (String, required) - Provider organization name
- `url` (String, optional) - Provider URL

**Returns:** `AgentProvider` instance

**Example:**

```ruby
provider = A2A::Models::AgentProvider.new(
  organization: 'Acme Corporation',
  url: 'https://acme.com'
)
```

#### Instance Methods

##### `#organization`

Returns the organization name.

**Returns:** `String`

##### `#url`

Returns the provider URL.

**Returns:** `String` or `nil`

##### `#to_h`

Converts to hash.

**Returns:** `Hash`

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates an AgentProvider from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `AgentProvider`

---

### AgentAuthentication

Represents authentication configuration for an agent.

**Source:** `lib/a2a/models/agent_authentication.rb`

#### Constructor

```ruby
A2A::Models::AgentAuthentication.new(
  schemes:,
  credentials: nil
)
```

**Parameters:**

- `schemes` (Array<String>, required) - Authentication schemes (e.g., ['bearer', 'basic'])
- `credentials` (String, optional) - Credentials endpoint URL

**Returns:** `AgentAuthentication` instance

**Example:**

```ruby
auth = A2A::Models::AgentAuthentication.new(
  schemes: ['bearer'],
  credentials: 'https://auth.example.com/token'
)
```

#### Instance Methods

##### `#schemes`

Returns the authentication schemes.

**Returns:** `Array<String>`

##### `#credentials`

Returns the credentials endpoint.

**Returns:** `String` or `nil`

##### `#to_h`

Converts to hash.

**Returns:** `Hash`

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates an AgentAuthentication from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `AgentAuthentication`

---

## Configuration

### PushNotificationConfig

Represents push notification configuration.

**Source:** `lib/a2a/models/push_notification_config.rb`

#### Constructor

```ruby
A2A::Models::PushNotificationConfig.new(
  url:,
  token: nil,
  authentication: nil
)
```

**Parameters:**

- `url` (String, required) - Push notification endpoint URL
- `token` (String, optional) - Authentication token
- `authentication` (Hash, optional) - Authentication configuration

**Returns:** `PushNotificationConfig` instance

**Example:**

```ruby
config = A2A::Models::PushNotificationConfig.new(
  url: 'https://client.example.com/notifications',
  token: 'secret-token-123',
  authentication: { type: 'bearer' }
)
```

#### Instance Methods

##### `#url`

Returns the notification URL.

**Returns:** `String`

##### `#token`

Returns the authentication token.

**Returns:** `String` or `nil`

##### `#authentication`

Returns the authentication config.

**Returns:** `Hash` or `nil`

##### `#to_h`

Converts to hash.

**Returns:** `Hash`

##### `#to_json(*args)`

Converts to JSON.

**Returns:** `String`

#### Class Methods

##### `.from_hash(hash)`

Creates a PushNotificationConfig from a hash.

**Parameters:**

- `hash` (Hash)

**Returns:** `PushNotificationConfig`

---

## Common Patterns

### Serialization

All models support bidirectional JSON conversion:

```ruby
# Object to Hash
hash = model.to_h

# Object to JSON string
json_string = model.to_json

# Hash to Object
model = ModelClass.from_hash(hash)

# JSON string to Object
require 'json'
model = ModelClass.from_hash(JSON.parse(json_string))
```

### Validation

Models perform validation in their constructors:

```ruby
# This will raise ArgumentError
invalid_state = A2A::Models::TaskState.new('invalid')

# This will raise ArgumentError
invalid_message = A2A::Models::Message.new(role: 'invalid', parts: [])

# This will raise ArgumentError
invalid_file = A2A::Models::FileContent.new() # needs bytes or uri
```

### Working with Parts

Parts support polymorphic creation:

```ruby
# Create from type-specific class
text_part = A2A::Models::TextPart.new(text: 'Hello')
file_part = A2A::Models::FilePart.new(file: {...})
data_part = A2A::Models::DataPart.new(data: {...})

# Create from hash using factory method
part = A2A::Models::Part.from_hash({ type: 'text', text: 'Hello' })
# => Returns TextPart instance

# Parts in collections
message = A2A::Models::Message.new(
  role: 'user',
  parts: [
    { type: 'text', text: 'Analyze this:' },
    { type: 'file', file: {...} }
  ]
)
# Parts are automatically normalized to Part instances
```

## See Also

- [API Overview](index.md)
- [Protocol Reference](protocol.md)
- [Client Reference](client.md)
- [Server Reference](server.md)
- [Quick Start Guide](../quickstart.md)

---

[Back to API Reference](index.md) | [Back to Documentation Home](../index.md)
