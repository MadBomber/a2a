# Guides

Comprehensive guides to help you master the A2A protocol and Ruby gem.

## Getting Started

New to A2A? Start here:

- **[Getting Started](getting-started.md)** - Complete tutorial from installation to your first A2A integration
- Learn the core concepts step-by-step
- Build a simple client and server
- Understand the protocol flow

## Core Concepts

Master the fundamental building blocks:

### [Creating Agent Cards](agent-cards.md)
- Define your agent's capabilities
- Publish agent metadata
- Configure streaming and notifications
- Define skills and input/output modes

### [Working with Tasks](tasks.md)
- Understand the task lifecycle
- Manage task states
- Handle task progression
- Work with session IDs for multi-turn conversations

### [Messages and Parts](messages.md)
- Create user and agent messages
- Work with polymorphic parts (Text, File, Data)
- Handle file content (bytes vs URIs)
- Structure complex messages

### [Handling Artifacts](artifacts.md)
- Generate agent outputs
- Work with multiple artifacts
- Stream partial results
- Add metadata to artifacts

### [Error Handling](errors.md)
- Understand the error hierarchy
- Handle JSON-RPC errors
- Manage A2A-specific errors
- Implement robust error handling

## By Use Case

Find guides for specific scenarios:

- **Building a Client**: See [Client Example](../examples/client.md)
- **Building a Server**: See [Server Example](../examples/server.md)
- **Streaming Responses**: See [Streaming Guide](../advanced/streaming.md)
- **Multi-turn Conversations**: See [Conversations Guide](../advanced/conversations.md)

## Best Practices

- Always validate input data
- Use factory methods (`Message.text`, etc.)
- Check task states with helper methods
- Handle all error types
- Test in isolation

## Quick Reference

### Common Patterns

```ruby
# Create agent card
agent = A2A::Models::AgentCard.new(...)

# Create message
msg = A2A::Models::Message.text(role: "user", text: "Hello")

# Create task
task = A2A::Models::Task.new(id: "123", status: { state: "submitted" })

# Check state
task.state.submitted?
task.state.terminal?

# Handle errors
begin
  # ...
rescue A2A::JSONRPCError => e
  puts "Error #{e.code}: #{e.message}"
end
```

## Additional Resources

- [API Reference](../api/index.md) - Complete API documentation
- [Examples](../examples/index.md) - Working code examples
- [Architecture](../architecture/index.md) - System design and principles
- [A2A Specification](https://google.github.io/A2A) - Official protocol spec

---

Choose a guide above to continue learning!
