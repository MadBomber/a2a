# Error Handling

The A2A gem provides a comprehensive error hierarchy for handling both JSON-RPC protocol errors and A2A-specific errors. This guide covers error types, handling strategies, and best practices.

## Table of Contents

- [Error Hierarchy](#error-hierarchy)
- [JSON-RPC Standard Errors](#json-rpc-standard-errors)
- [A2A-Specific Errors](#a2a-specific-errors)
- [Error Handling Patterns](#error-handling-patterns)
- [Protocol Error Responses](#protocol-error-responses)
- [Best Practices](#best-practices)
- [Examples](#examples)

## Error Hierarchy

All errors inherit from a common base:

```
A2A::Error (StandardError)
  └── A2A::JSONRPCError
        ├── A2A::JSONParseError (-32700)
        ├── A2A::InvalidRequestError (-32600)
        ├── A2A::MethodNotFoundError (-32601)
        ├── A2A::InvalidParamsError (-32602)
        ├── A2A::InternalError (-32603)
        ├── A2A::TaskNotFoundError (-32001)
        ├── A2A::TaskNotCancelableError (-32002)
        ├── A2A::PushNotificationNotSupportedError (-32003)
        └── A2A::UnsupportedOperationError (-32004)
```

## JSON-RPC Standard Errors

### JSONParse Error (-32700)

Invalid JSON payload:

```ruby
begin
  # Parse invalid JSON
  raise A2A::JSONParseError.new(data: { received: "invalid json{" })
rescue A2A::JSONParseError => e
  puts e.message  # => "Invalid JSON payload"
  puts e.code     # => -32700
  puts e.data     # => { received: "invalid json{" }
end
```

### InvalidRequestError (-32600)

Request validation failed:

```ruby
begin
  # Missing required field
  raise A2A::InvalidRequestError.new(
    data: { missing_fields: ["method"] }
  )
rescue A2A::InvalidRequestError => e
  puts e.message  # => "Request payload validation error"
  puts e.code     # => -32600
end
```

### MethodNotFoundError (-32601)

RPC method not found:

```ruby
begin
  # Unknown method
  raise A2A::MethodNotFoundError.new(
    data: { method: "tasks/unknownMethod" }
  )
rescue A2A::MethodNotFoundError => e
  puts e.message  # => "Method not found"
  puts e.code     # => -32601
end
```

### InvalidParamsError (-32602)

Invalid parameters:

```ruby
begin
  raise A2A::InvalidParamsError.new(
    data: { param: "taskId", error: "must be a string" }
  )
rescue A2A::InvalidParamsError => e
  puts e.message  # => "Invalid parameters"
  puts e.code     # => -32602
end
```

### InternalError (-32603)

Server internal error:

```ruby
begin
  raise A2A::InternalError.new(
    data: { error: "Database connection failed" }
  )
rescue A2A::InternalError => e
  puts e.message  # => "Internal error"
  puts e.code     # => -32603
end
```

## A2A-Specific Errors

### TaskNotFoundError (-32001)

Task ID not found:

```ruby
begin
  raise A2A::TaskNotFoundError.new
rescue A2A::TaskNotFoundError => e
  puts e.message  # => "Task not found"
  puts e.code     # => -32001
end
```

### TaskNotCancelableError (-32002)

Task cannot be canceled:

```ruby
begin
  # Task already completed
  raise A2A::TaskNotCancelableError.new
rescue A2A::TaskNotCancelableError => e
  puts e.message  # => "Task cannot be canceled"
  puts e.code     # => -32002
end
```

### PushNotificationNotSupportedError (-32003)

Push notifications not supported:

```ruby
begin
  raise A2A::PushNotificationNotSupportedError.new
rescue A2A::PushNotificationNotSupportedError => e
  puts e.message  # => "Push Notification is not supported"
  puts e.code     # => -32003
end
```

### UnsupportedOperationError (-32004)

Operation not supported:

```ruby
begin
  raise A2A::UnsupportedOperationError.new
rescue A2A::UnsupportedOperationError => e
  puts e.message  # => "This operation is not supported"
  puts e.code     # => -32004
end
```

## Error Handling Patterns

### Pattern: Catch All JSON-RPC Errors

```ruby
begin
  # A2A operation
rescue A2A::JSONRPCError => e
  puts "Protocol Error: #{e.message}"
  puts "Error Code: #{e.code}"
  puts "Data: #{e.data.inspect}" if e.data
end
```

### Pattern: Specific Error Handling

```ruby
begin
  # Client operation
  client.get_task(task_id: "nonexistent")
rescue A2A::TaskNotFoundError => e
  puts "Task not found - it may have been deleted"
rescue A2A::InvalidParamsError => e
  puts "Invalid task ID provided"
rescue A2A::JSONRPCError => e
  puts "Other protocol error: #{e.message}"
end
```

### Pattern: Error Recovery

```ruby
def get_task_with_retry(client, task_id, max_retries: 3)
  retries = 0

  begin
    client.get_task(task_id: task_id)
  rescue A2A::InternalError => e
    retries += 1
    if retries < max_retries
      sleep(2 ** retries)  # Exponential backoff
      retry
    else
      raise
    end
  rescue A2A::TaskNotFoundError
    nil  # Return nil for not found
  end
end
```

### Pattern: Error Logging

```ruby
def handle_a2a_error(error)
  case error
  when A2A::TaskNotFoundError
    logger.warn("Task not found: #{error.message}")
  when A2A::InvalidParamsError
    logger.error("Invalid parameters: #{error.data}")
  when A2A::InternalError
    logger.fatal("Internal error: #{error.message}")
    notify_admins(error)
  else
    logger.error("A2A error: #{error.class} - #{error.message}")
  end
end

begin
  # Operation
rescue A2A::JSONRPCError => e
  handle_a2a_error(e)
  raise  # Re-raise if needed
end
```

## Protocol Error Responses

### Creating Error Responses

```ruby
require 'a2a'

# Create error response
error_response = A2A::Protocol::Response.error(
  id: "request-123",
  error: {
    code: -32001,
    message: "Task not found",
    data: { task_id: "task-456" }
  }
)

puts error_response.success?  # => false
puts error_response.error     # => { code: -32001, ... }
```

### Server Error Handling

```ruby
class MyA2AServer < A2A::Server::Base
  def handle_get_task(params)
    task_id = params['taskId']

    task = find_task(task_id)
    if task.nil?
      raise A2A::TaskNotFoundError.new
    end

    task
  rescue A2A::TaskNotFoundError => e
    # Return error response
    {
      code: e.code,
      message: e.message,
      data: { task_id: task_id }
    }
  end
end
```

## Best Practices

### 1. Catch Specific Errors First

```ruby
# Good: Specific to general
begin
  operation
rescue A2A::TaskNotFoundError => e
  handle_not_found
rescue A2A::InvalidParamsError => e
  handle_invalid_params
rescue A2A::JSONRPCError => e
  handle_general_error
end

# Bad: General first catches everything
begin
  operation
rescue A2A::JSONRPCError => e  # Too broad!
  handle_error
rescue A2A::TaskNotFoundError => e  # Never reached!
  handle_not_found
end
```

### 2. Include Helpful Error Data

```ruby
# Good: Include context
raise A2A::InvalidParamsError.new(
  data: {
    param: "message",
    expected: "Message object",
    received: message.class.name
  }
)

# Basic: Minimal info
raise A2A::InvalidParamsError.new
```

### 3. Log Errors Appropriately

```ruby
# Good: Log with context
begin
  task = client.get_task(task_id: id)
rescue A2A::TaskNotFoundError => e
  logger.warn("Task #{id} not found", error: e)
  nil
rescue A2A::JSONRPCError => e
  logger.error("A2A error fetching task #{id}", error: e, code: e.code)
  raise
end
```

### 4. Provide User-Friendly Messages

```ruby
# Good: User-friendly messages
begin
  client.send_task(...)
rescue A2A::InvalidParamsError => e
  flash[:error] = "Invalid request. Please check your input."
rescue A2A::InternalError => e
  flash[:error] = "Service temporarily unavailable. Please try again later."
end
```

## Examples

### Example 1: Client Error Handling

```ruby
require 'a2a'

class A2AClient < A2A::Client::Base
  def send_message_safely(task_id, message)
    begin
      send_task(task_id: task_id, message: message)
    rescue A2A::InvalidParamsError => e
      puts "Invalid message format: #{e.data}"
      nil
    rescue A2A::InternalError => e
      puts "Server error. Please try again later."
      nil
    rescue A2A::JSONRPCError => e
      puts "Unexpected error (#{e.code}): #{e.message}"
      nil
    end
  end
end
```

### Example 2: Validation Errors

```ruby
require 'a2a'

def validate_and_create_task(params)
  errors = []

  if params[:id].nil? || params[:id].empty?
    errors << "Task ID is required"
  end

  if params[:status].nil?
    errors << "Status is required"
  end

  unless errors.empty?
    raise A2A::InvalidParamsError.new(
      data: { validation_errors: errors }
    )
  end

  A2A::Models::Task.new(**params)
rescue ArgumentError => e
  raise A2A::InvalidParamsError.new(
    data: { error: e.message }
  )
end

begin
  task = validate_and_create_task(id: "", status: nil)
rescue A2A::InvalidParamsError => e
  puts "Validation failed:"
  e.data[:validation_errors].each { |err| puts "  - #{err}" }
end
```

### Example 3: Server Implementation with Error Handling

```ruby
require 'a2a'

class MyAgent < A2A::Server::Base
  def handle_send_task(params)
    message = parse_message(params)
    validate_message(message)

    # Process task
    result = process_task(message)

    A2A::Models::Task.new(
      id: params['taskId'],
      status: { state: "completed" },
      artifacts: [result]
    )
  rescue ArgumentError => e
    raise A2A::InvalidParamsError.new(data: { error: e.message })
  rescue StandardError => e
    logger.error("Task processing failed", error: e)
    raise A2A::InternalError.new(data: { error: "Processing failed" })
  end

  private

  def parse_message(params)
    A2A::Models::Message.from_hash(params['message'])
  rescue => e
    raise A2A::InvalidParamsError.new(
      data: { field: "message", error: e.message }
    )
  end

  def validate_message(message)
    if message.parts.empty?
      raise A2A::InvalidParamsError.new(
        data: { field: "message.parts", error: "cannot be empty" }
      )
    end
  end
end
```

### Example 4: Retry with Exponential Backoff

```ruby
def robust_task_submission(client, task_id, message, max_retries: 3)
  retries = 0

  begin
    client.send_task(task_id: task_id, message: message)
  rescue A2A::InternalError, A2A::Error => e
    retries += 1

    if retries < max_retries
      wait_time = 2 ** retries
      puts "Retry #{retries}/#{max_retries} in #{wait_time}s..."
      sleep(wait_time)
      retry
    else
      puts "Max retries reached. Giving up."
      raise
    end
  rescue A2A::TaskNotFoundError
    puts "Task does not exist"
    nil
  rescue A2A::InvalidParamsError => e
    puts "Invalid request: #{e.data}"
    nil
  end
end
```

## See Also

- [Working with Tasks](tasks.md) - Task lifecycle and management
- [Messages and Parts](messages.md) - Understanding message structure
- [API Reference: Protocol](../api/protocol.md) - Protocol error details
- [Building a Server](../examples/server.md) - Server error handling
- [Building a Client](../examples/client.md) - Client error handling

---

[Back to Guides](index.md) | [Home](../index.md)
