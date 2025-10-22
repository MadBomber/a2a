# Protocol API Reference

Complete reference for the A2A protocol classes (`A2A::Protocol` namespace).

## Overview

The Protocol layer implements the JSON-RPC 2.0 protocol used for communication in the A2A system. This layer provides classes for creating requests, handling responses, and managing protocol-level errors.

## Table of Contents

- [Request](#request)
- [Response](#response)
- [Error](#error)
- [Common Patterns](#common-patterns)

---

## Request

Represents a JSON-RPC 2.0 request in the A2A protocol.

**Source:** `lib/a2a/protocol/request.rb`

### JSON-RPC Version

All requests use JSON-RPC version `2.0`, defined by the constant `JSONRPC_VERSION`.

### Constructor

```ruby
A2A::Protocol::Request.new(
  method:,
  params: nil,
  id: nil
)
```

**Parameters:**

- `method` (String, required) - The RPC method name to invoke
- `params` (Hash or Array, optional) - Method parameters
- `id` (String or Integer, optional) - Request identifier (nil for notifications)

**Returns:** `Request` instance

**Example:**

```ruby
# Standard request
request = A2A::Protocol::Request.new(
  method: 'tasks/send',
  params: {
    taskId: 'task-123',
    message: { role: 'user', parts: [...] }
  },
  id: 1
)

# Notification (no id, no response expected)
notification = A2A::Protocol::Request.new(
  method: 'tasks/cancel',
  params: { taskId: 'task-456' }
)
```

### Instance Methods

#### `#jsonrpc`

Returns the JSON-RPC version.

**Returns:** `String` (always "2.0")

```ruby
request.jsonrpc  # => "2.0"
```

#### `#id`

Returns the request identifier.

**Returns:** `String`, `Integer`, or `nil`

```ruby
request.id  # => 1
```

#### `#method`

Returns the RPC method name.

**Returns:** `String`

```ruby
request.method  # => "tasks/send"
```

#### `#params`

Returns the method parameters.

**Returns:** `Hash`, `Array`, or `nil`

```ruby
request.params  # => { taskId: "task-123", ... }
```

#### `#to_h`

Converts the request to a hash representation.

**Returns:** `Hash`

```ruby
request.to_h
# => {
#   jsonrpc: "2.0",
#   id: 1,
#   method: "tasks/send",
#   params: { ... }
# }
```

#### `#to_json(*args)`

Converts the request to a JSON string.

**Returns:** `String`

**Example:**

```ruby
json = request.to_json
# => '{"jsonrpc":"2.0","id":1,"method":"tasks/send","params":{...}}'
```

### Class Methods

#### `.from_hash(hash)`

Creates a Request instance from a hash.

**Parameters:**

- `hash` (Hash) - Hash representation (supports both symbol and string keys)

**Returns:** `Request`

**Example:**

```ruby
request = A2A::Protocol::Request.from_hash({
  'jsonrpc' => '2.0',
  'id' => 1,
  'method' => 'tasks/get',
  'params' => { 'taskId' => 'task-789' }
})
```

### A2A Protocol Methods

The following methods are defined in the A2A protocol specification:

#### Task Management

- `tasks/send` - Submit a new task
- `tasks/sendSubscribe` - Submit a task with streaming
- `tasks/get` - Get task status
- `tasks/cancel` - Cancel a task
- `tasks/resubscribe` - Resubscribe to task updates

#### Push Notifications

- `tasks/pushNotification/set` - Configure push notifications
- `tasks/pushNotification/get` - Get push notification configuration

**Example:**

```ruby
# Send a task
request = A2A::Protocol::Request.new(
  method: 'tasks/send',
  params: {
    taskId: SecureRandom.uuid,
    message: {
      role: 'user',
      parts: [{ type: 'text', text: 'Hello!' }]
    }
  },
  id: 1
)

# Get task status
request = A2A::Protocol::Request.new(
  method: 'tasks/get',
  params: { taskId: 'task-123' },
  id: 2
)

# Cancel a task
request = A2A::Protocol::Request.new(
  method: 'tasks/cancel',
  params: { taskId: 'task-123' },
  id: 3
)
```

---

## Response

Represents a JSON-RPC 2.0 response in the A2A protocol.

**Source:** `lib/a2a/protocol/response.rb`

### JSON-RPC Version

All responses use JSON-RPC version `2.0`, defined by the constant `JSONRPC_VERSION`.

### Constructor

```ruby
A2A::Protocol::Response.new(
  id: nil,
  result: nil,
  error: nil
)
```

**Parameters:**

- `id` (String or Integer, optional) - Request identifier (matches the request)
- `result` (Object, optional) - Result data (for successful responses)
- `error` (Hash, optional) - Error data (for error responses)

**Note:** Either `result` or `error` should be present, but not both.

**Returns:** `Response` instance

**Example:**

```ruby
# Success response
response = A2A::Protocol::Response.new(
  id: 1,
  result: {
    id: 'task-123',
    status: { state: 'submitted', timestamp: '...' }
  }
)

# Error response
response = A2A::Protocol::Response.new(
  id: 1,
  error: {
    code: -32001,
    message: 'Task not found',
    data: { taskId: 'task-999' }
  }
)
```

### Instance Methods

#### `#jsonrpc`

Returns the JSON-RPC version.

**Returns:** `String` (always "2.0")

```ruby
response.jsonrpc  # => "2.0"
```

#### `#id`

Returns the response identifier (matches the request ID).

**Returns:** `String`, `Integer`, or `nil`

```ruby
response.id  # => 1
```

#### `#result`

Returns the result data.

**Returns:** `Object` or `nil`

```ruby
response.result  # => { id: "task-123", ... }
```

#### `#error`

Returns the error data.

**Returns:** `Hash` or `nil`

```ruby
response.error  # => { code: -32001, message: "Task not found" }
```

#### `#success?`

Returns whether the response indicates success (no error).

**Returns:** `Boolean`

```ruby
response.success?  # => true if no error, false if error present
```

#### `#to_h`

Converts the response to a hash representation.

**Returns:** `Hash`

```ruby
response.to_h
# => {
#   jsonrpc: "2.0",
#   id: 1,
#   result: { ... }
# }
```

**Note:** If `result` responds to `to_h`, it will be called automatically.

#### `#to_json(*args)`

Converts the response to a JSON string.

**Returns:** `String`

**Example:**

```ruby
json = response.to_json
# => '{"jsonrpc":"2.0","id":1,"result":{...}}'
```

### Class Methods

#### `.from_hash(hash)`

Creates a Response instance from a hash.

**Parameters:**

- `hash` (Hash) - Hash representation (supports both symbol and string keys)

**Returns:** `Response`

**Example:**

```ruby
response = A2A::Protocol::Response.from_hash({
  'jsonrpc' => '2.0',
  'id' => 1,
  'result' => { 'id' => 'task-123', 'status' => { ... } }
})
```

#### `.success(id:, result:)`

Convenience method to create a success response.

**Parameters:**

- `id` (String or Integer, required) - Request identifier
- `result` (Object, required) - Result data

**Returns:** `Response`

**Example:**

```ruby
response = A2A::Protocol::Response.success(
  id: 1,
  result: task.to_h
)
```

#### `.error(id:, error:)`

Convenience method to create an error response.

**Parameters:**

- `id` (String or Integer, required) - Request identifier
- `error` (Hash or Error, required) - Error data

**Returns:** `Response`

**Example:**

```ruby
response = A2A::Protocol::Response.error(
  id: 1,
  error: {
    code: -32001,
    message: 'Task not found'
  }
)

# Or using an Error object
error_obj = A2A::Protocol::Error.new(
  code: -32001,
  message: 'Task not found'
)
response = A2A::Protocol::Response.error(id: 1, error: error_obj.to_h)
```

---

## Error

Represents a JSON-RPC error in a protocol message.

**Source:** `lib/a2a/protocol/error.rb`

### Constructor

```ruby
A2A::Protocol::Error.new(
  code:,
  message:,
  data: nil
)
```

**Parameters:**

- `code` (Integer, required) - Error code
- `message` (String, required) - Error message
- `data` (Object, optional) - Additional error data

**Returns:** `Error` instance

**Example:**

```ruby
error = A2A::Protocol::Error.new(
  code: -32001,
  message: 'Task not found',
  data: { taskId: 'task-999' }
)
```

### Instance Methods

#### `#code`

Returns the error code.

**Returns:** `Integer`

```ruby
error.code  # => -32001
```

#### `#message`

Returns the error message.

**Returns:** `String`

```ruby
error.message  # => "Task not found"
```

#### `#data`

Returns additional error data.

**Returns:** `Object` or `nil`

```ruby
error.data  # => { taskId: "task-999" }
```

#### `#to_h`

Converts the error to a hash representation.

**Returns:** `Hash`

```ruby
error.to_h
# => {
#   code: -32001,
#   message: "Task not found",
#   data: { taskId: "task-999" }
# }
```

#### `#to_json(*args)`

Converts the error to a JSON string.

**Returns:** `String`

### Class Methods

#### `.from_hash(hash)`

Creates an Error instance from a hash.

**Parameters:**

- `hash` (Hash) - Hash representation (supports both symbol and string keys)

**Returns:** `Error`

**Example:**

```ruby
error = A2A::Protocol::Error.from_hash({
  'code' => -32001,
  'message' => 'Task not found',
  'data' => { 'taskId' => 'task-999' }
})
```

#### `.from_exception(exception)`

Creates an Error from a Ruby exception.

**Parameters:**

- `exception` (Exception) - Ruby exception object

**Returns:** `Error`

**Behavior:**

- If exception is an `A2A::JSONRPCError`, uses its code, message, and data
- Otherwise, creates an Internal Error (-32603) with the exception message

**Example:**

```ruby
# From A2A error
begin
  raise A2A::TaskNotFoundError.new
rescue => e
  error = A2A::Protocol::Error.from_exception(e)
  # => Error with code: -32001, message: "Task not found"
end

# From standard exception
begin
  raise StandardError, "Something went wrong"
rescue => e
  error = A2A::Protocol::Error.from_exception(e)
  # => Error with code: -32603, message: "Something went wrong"
end
```

### Standard Error Codes

JSON-RPC 2.0 defines the following standard error codes:

| Code | Constant | Description |
|------|----------|-------------|
| -32700 | Parse Error | Invalid JSON |
| -32600 | Invalid Request | Request validation error |
| -32601 | Method Not Found | Method doesn't exist |
| -32602 | Invalid Params | Invalid method parameters |
| -32603 | Internal Error | Internal server error |

### A2A-Specific Error Codes

The A2A protocol defines additional error codes:

| Code | Constant | Description |
|------|----------|-------------|
| -32001 | Task Not Found | Task ID doesn't exist |
| -32002 | Task Not Cancelable | Task cannot be canceled |
| -32003 | Push Notification Not Supported | Push notifications unavailable |
| -32004 | Unsupported Operation | Operation not supported |

See the [Error Handling](index.md#error-handling) section in the API overview for exception classes.

---

## Common Patterns

### Creating a Request-Response Pair

```ruby
# Client creates a request
request = A2A::Protocol::Request.new(
  method: 'tasks/send',
  params: {
    taskId: 'task-123',
    message: { role: 'user', parts: [...] }
  },
  id: 1
)

# Server processes and creates a response
if success
  response = A2A::Protocol::Response.success(
    id: request.id,
    result: task.to_h
  )
else
  response = A2A::Protocol::Response.error(
    id: request.id,
    error: {
      code: -32001,
      message: 'Task not found'
    }
  )
end
```

### Handling Errors

```ruby
# Create an error from an exception
begin
  # ... some operation ...
  raise A2A::TaskNotFoundError.new
rescue A2A::JSONRPCError => e
  error = A2A::Protocol::Error.from_exception(e)
  response = A2A::Protocol::Response.error(
    id: request.id,
    error: error.to_h
  )
end
```

### Checking Response Success

```ruby
response = client.send_request(request)

if response.success?
  # Handle result
  task = A2A::Models::Task.from_hash(response.result)
  puts "Task state: #{task.state}"
else
  # Handle error
  error = response.error
  puts "Error #{error['code']}: #{error['message']}"
end
```

### Serialization

All protocol classes support JSON serialization:

```ruby
# Request to JSON
request = A2A::Protocol::Request.new(method: 'tasks/get', params: {}, id: 1)
json_string = request.to_json
# => '{"jsonrpc":"2.0","id":1,"method":"tasks/get","params":{}}'

# JSON to Request
require 'json'
hash = JSON.parse(json_string)
request = A2A::Protocol::Request.from_hash(hash)

# Response to JSON
response = A2A::Protocol::Response.success(id: 1, result: { status: 'ok' })
json_string = response.to_json

# JSON to Response
hash = JSON.parse(json_string)
response = A2A::Protocol::Response.from_hash(hash)
```

### Notification Requests

Requests without an `id` are notifications (no response expected):

```ruby
# Notification (no response expected)
notification = A2A::Protocol::Request.new(
  method: 'tasks/update',
  params: { taskId: 'task-123', status: 'updated' }
  # Note: no id parameter
)

# Server should not send a response for notifications
if request.id.nil?
  # This is a notification, process but don't respond
  process_notification(request)
else
  # This is a regular request, send a response
  response = process_request(request)
  send_response(response)
end
```

### Batch Requests

While the A2A gem doesn't provide special handling for batch requests, JSON-RPC 2.0 supports them:

```ruby
# Array of requests
batch = [
  A2A::Protocol::Request.new(method: 'tasks/get', params: { taskId: '1' }, id: 1),
  A2A::Protocol::Request.new(method: 'tasks/get', params: { taskId: '2' }, id: 2),
  A2A::Protocol::Request.new(method: 'tasks/get', params: { taskId: '3' }, id: 3)
]

# Serialize as JSON array
json = batch.map(&:to_h).to_json
# => '[{"jsonrpc":"2.0","id":1,...},{"jsonrpc":"2.0","id":2,...},...]'

# Server responds with array of responses
responses = [
  A2A::Protocol::Response.success(id: 1, result: task1),
  A2A::Protocol::Response.success(id: 2, result: task2),
  A2A::Protocol::Response.error(id: 3, error: { code: -32001, message: '...' })
]
```

### Model Integration

Protocol classes work seamlessly with model classes:

```ruby
# Create a task
task = A2A::Models::Task.new(
  id: 'task-123',
  status: { state: 'submitted' }
)

# Create a response with the task
response = A2A::Protocol::Response.success(
  id: 1,
  result: task.to_h  # Task automatically converts to hash
)

# Parse response and recreate task
if response.success?
  task = A2A::Models::Task.from_hash(response.result)
end
```

## Wire Format

The JSON-RPC 2.0 wire format for A2A protocol:

### Request Format

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tasks/send",
  "params": {
    "taskId": "task-123",
    "message": {
      "role": "user",
      "parts": [
        {
          "type": "text",
          "text": "Hello, agent!"
        }
      ]
    }
  }
}
```

### Success Response Format

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "id": "task-123",
    "sessionId": "session-abc",
    "status": {
      "state": "submitted",
      "timestamp": "2025-01-15T10:30:00Z"
    }
  }
}
```

### Error Response Format

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32001,
    "message": "Task not found",
    "data": {
      "taskId": "task-999"
    }
  }
}
```

### Notification Format

```json
{
  "jsonrpc": "2.0",
  "method": "tasks/update",
  "params": {
    "taskId": "task-123",
    "status": "completed"
  }
}
```

## See Also

- [API Overview](index.md)
- [Models Reference](models.md)
- [Client Reference](client.md)
- [Server Reference](server.md)
- [Error Handling](index.md#error-handling)
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)

---

[Back to API Reference](index.md) | [Back to Documentation Home](../index.md)
