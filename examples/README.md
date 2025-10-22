# A2A Ruby Gem Examples

This directory contains executable Ruby programs demonstrating the A2A (Agent-to-Agent) protocol implementation.

## Directory Structure

```
examples/
├── basic/          # Core data model examples
├── client/         # HTTP client implementations
└── server/         # HTTP server implementations
```

## Quick Start

### One-Command Demo

The easiest way to see A2A in action:

```bash
cd examples
ruby run_demo.rb
```

This automatically:
1. Starts an A2A echo server in the background
2. Runs a conversation client showing 3-turn interaction
3. Displays complete request/response flow with timestamps
4. Cleans up the server when finished

Server logs are saved to `/tmp/a2a_server.log`.

### Running Basic Examples

Basic examples demonstrate the core A2A data models:

```bash
# Complete conversation workflow
ruby examples/basic/complete_conversation_workflow.rb

# Error handling and recovery
ruby examples/basic/error_recovery_workflow.rb
```

### Running Client Examples

Client examples require a running A2A server:

```bash
# Simple Faraday-based client
ruby examples/client/simple_faraday_client.rb

# Production-ready client with retries
ruby examples/client/production_client.rb

# Multi-turn conversation client
ruby examples/client/conversation_client.rb
```

### Running Server Examples

Server examples provide A2A-compatible HTTP servers:

```bash
# Simple Sinatra server (runs on port 4567)
ruby examples/server/simple_sinatra_server.rb
```

Test the server with curl:
```bash
# Get agent card
curl http://localhost:4567/.well-known/agent.json | jq

# Send a task
curl -X POST http://localhost:4567/a2a \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": "1",
    "method": "tasks/send",
    "params": {
      "taskId": "task-123",
      "message": {
        "role": "user",
        "parts": [{"type": "text", "text": "Hello, world!"}]
      }
    }
  }' | jq
```

## Complete Example List

### Basic Examples (`basic/`)

| File | Description |
|------|-------------|
| `complete_conversation_workflow.rb` | Multi-turn conversation with session management |
| `error_recovery_workflow.rb` | Error handling and recovery patterns |

### Client Examples (`client/`)

| File | Description | Dependencies |
|------|-------------|--------------|
| `simple_faraday_client.rb` | Basic HTTP client using Faraday | faraday |
| `production_client.rb` | Production-ready client with retries and error handling | faraday, faraday-retry |
| `conversation_client.rb` | Multi-turn conversation manager | Requires `production_client.rb` |
| `net_http_client.rb` | Pure Ruby client using only Net::HTTP (no external dependencies) | none (stdlib only) |
| `cli_client.rb` | Command-line interface for A2A agents | Requires `production_client.rb` |

### Server Examples (`server/`)

| File | Description | Dependencies |
|------|-------------|--------------|
| `simple_sinatra_server.rb` | Basic A2A server implementation | sinatra |
| `production_server.rb` | Production server with background processing, SSE streaming, push notifications | sinatra, concurrent-ruby |
| `translation_agent_server.rb` | Translation service agent | Requires `production_server.rb` |
| `multi_agent_server.rb` | Multi-agent server hosting multiple agents | Requires `production_server.rb` |

## Installation

Ensure you have the A2A gem installed:

```bash
# From the project root
bundle install

# Or install the gem directly
gem install a2a
```

### Additional Dependencies

For client examples:
```bash
gem install faraday faraday-retry
```

For server examples:
```bash
gem install sinatra puma
```

## Usage Patterns

### Client-Server Integration

1. **Start a server:**
   ```bash
   ruby examples/server/simple_sinatra_server.rb
   ```

2. **In another terminal, run a client:**
   ```bash
   # Edit the client file to point to http://localhost:4567
   ruby examples/client/simple_faraday_client.rb
   ```

### Customizing Examples

All examples are designed to be modified and extended. Key customization points:

**Clients:**
- Change `agent_url` to point to your A2A server
- Modify timeout and retry settings
- Add custom headers for authentication
- Implement custom error handling

**Servers:**
- Implement custom message processors
- Add authentication middleware
- Integrate with databases or external services
- Add logging and monitoring

## Example Workflows

### Complete Client-Server Interaction

```ruby
# 1. Start server (in one terminal)
ruby examples/server/simple_sinatra_server.rb

# 2. Use client (in another terminal)
require_relative 'examples/client/simple_faraday_client'

client = SimpleA2AClient.new('http://localhost:4567')
agent = client.discover
puts agent.name  # => "Simple Echo Agent"

message = A2A::Models::Message.text(role: "user", text: "Hello!")
task = client.send_task(task_id: SecureRandom.uuid, message: message)
puts task.artifacts.first.parts.first.text  # => "Echo: Hello!"
```

### Multi-Turn Conversation

```ruby
require_relative 'examples/client/conversation_client'

conv = ConversationClient.new('http://localhost:4567')

# Turn 1
response = conv.send("Translate 'hello' to Spanish")
puts response  # => "hola"

# Turn 2 (context maintained via session_id)
response = conv.send("Now to French")
puts response  # => "bonjour"

# View full history
conv.print_history
```

## Testing

Run the basic examples to verify your setup:

```bash
# Should execute without errors
ruby examples/basic/complete_conversation_workflow.rb
ruby examples/basic/error_recovery_workflow.rb
```

Expected output shows timestamped logger messages tracking the workflow.

## Development

### Creating New Examples

1. Copy an existing example as a template
2. Add documentation header explaining the example
3. Include usage instructions in comments
4. Make the file executable: `chmod +x examples/category/your_example.rb`
5. Add entry to this README

### Logging

All examples use Ruby's standard Logger class for production-ready logging:

```ruby
require 'logger'

logger = Logger.new($stdout)
logger.level = Logger::INFO
logger.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime('%H:%M:%S')}] #{severity}: #{msg}\n"
end

logger.info "Starting process"
logger.debug { "variable1=#{variable1}, variable2=#{variable2}" }
```

Log levels used:
- **INFO**: General flow and operational messages
- **ERROR**: Error conditions
- **WARN**: Warning messages
- **DEBUG**: Detailed debugging information

## Common Issues

### Connection Errors

```
Error: Connection failed
```

**Solution:** Ensure the server is running and the URL is correct.

### Missing Dependencies

```
LoadError: cannot load such file -- faraday
```

**Solution:** Install required gems:
```bash
gem install faraday faraday-retry sinatra
```

### Port Already in Use

```
Address already in use - bind(2) for "127.0.0.1" port 4567
```

**Solution:** Stop other processes on port 4567 or change the port in the server code.

## Additional Resources

- [Main Documentation](../docs/index.md)
- [Getting Started Guide](../docs/guides/getting-started.md)
- [API Reference](../docs/api/index.md)
- [Client Examples Documentation](../docs/examples/client.md)
- [Server Examples Documentation](../docs/examples/server.md)
- [Protocol Specification](../docs/protocol-spec.md)

## Contributing

When adding new examples:

1. Follow the established patterns
2. Include clear documentation
3. Make examples self-contained
4. Test thoroughly before submitting
5. Update this README with the new example

## License

These examples are part of the A2A Ruby gem and are released under the same MIT License.
