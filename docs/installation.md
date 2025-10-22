# Installation

This guide will help you install the A2A Ruby gem and get it running on your system.

## Prerequisites

### Required
- **Ruby**: Version 3.4.0 or higher
- **RubyGems**: Usually comes with Ruby

### Recommended
- **git**: For version control
- **bundler**: For dependency management

## Installation Methods

### Method 1: Install from RubyGems (Recommended)

The easiest way to install A2A is through RubyGems:

```bash
gem install a2a
```

### Method 2: Install from Source

If you want the latest development version:

```bash
git clone https://github.com/madbomber/a2a.git
cd a2a
bundle install
rake install
```

### Method 3: Using Bundler

Add to your Gemfile:

```ruby
gem 'a2a'
```

Then run:

```bash
bundle install
```

## Verify Installation

After installation, verify that A2A is working:

```bash
ruby -r a2a -e "puts A2A.version"
```

You should see the version number printed (e.g., `0.1.0.pre`).

## Quick Test

Let's verify everything works with a quick Ruby script:

```ruby
#!/usr/bin/env ruby
require 'a2a'

# Create a simple agent card
agent = A2A::Models::AgentCard.new(
  name: "Test Agent",
  url: "https://example.com/a2a",
  version: "1.0.0",
  capabilities: { streaming: false },
  skills: [{ id: "test", name: "Test Skill" }]
)

puts "✓ A2A gem loaded successfully!"
puts "✓ Agent created: #{agent.name}"
puts "✓ Version: #{A2A.version}"
```

Save this as `test_a2a.rb` and run:

```bash
ruby test_a2a.rb
```

## Initial Setup

### 1. Create a Project Directory

If you're building an A2A client or server:

```bash
mkdir my_a2a_project
cd my_a2a_project
```

### 2. Initialize Bundler (Optional)

```bash
bundle init
```

Edit the `Gemfile` to add the a2a gem:

```ruby
source 'https://rubygems.org'

gem 'a2a'

# Optional: Add web framework for server implementations
gem 'sinatra'  # or 'rails', 'roda', etc.

# Optional: Add HTTP client for client implementations
gem 'faraday'

# Optional: Development dependencies
group :development do
  gem 'rspec'
  gem 'rubocop'
end
```

Then install:

```bash
bundle install
```

## Testing Your Installation

### Test 1: Load the Gem

```bash
ruby -r a2a -e "puts 'A2A loaded successfully'"
```

### Test 2: Create Models

Create a file `test_models.rb`:

```ruby
require 'a2a'

# Test creating different models
message = A2A::Models::Message.text(
  role: "user",
  text: "Hello, agent!"
)

task = A2A::Models::Task.new(
  id: "test-123",
  status: { state: "submitted" }
)

puts "Message created: #{message.parts.first.text}"
puts "Task state: #{task.state}"
puts "All tests passed!"
```

Run it:

```bash
ruby test_models.rb
```

### Test 3: Run Examples

The gem includes working examples:

```bash
ruby examples/basic_usage.rb
```

You should see comprehensive output demonstrating various A2A features.

## Troubleshooting

### Common Issues

#### "Cannot load such file -- a2a"

**Solution**: Make sure the gem is installed:

```bash
gem list a2a
```

If not listed, reinstall:

```bash
gem install a2a
```

#### "Wrong Ruby version"

**Solution**: A2A requires Ruby 3.4.0 or higher. Check your version:

```bash
ruby --version
```

Upgrade Ruby if needed using rbenv, rvm, or your system package manager.

#### Permission Errors

**Solution**: Try installing with the `--user-install` flag:

```bash
gem install a2a --user-install
```

Or use bundler in your project instead of system-wide installation.

#### "LoadError" when requiring

**Solution**: Ensure your Ruby's gem bin directory is in your PATH:

```bash
echo $PATH
gem environment
```

Add the gems directory to your PATH if needed.

### Getting Help

If you encounter issues:

1. Check the [GitHub Issues](https://github.com/madbomber/a2a/issues)
2. Review the [Examples](examples/index.md)
3. Read the [API Documentation](api/index.md)
4. Create a new issue with:
   - Your OS and Ruby version (`ruby --version`)
   - The exact error message
   - Steps to reproduce

## Development Installation

For contributing to A2A development:

```bash
# Clone the repository
git clone https://github.com/madbomber/a2a.git
cd a2a

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Build the gem
bundle exec rake build

# Install locally
bundle exec rake install
```

## Additional Tools

### Code Quality Tools

```bash
# Install development tools
gem install rubocop
gem install yard
gem install rspec
```

### Type Checking

A2A is designed to work with RBS:

```bash
gem install rbs
gem install steep

# Type check (once RBS signatures are added)
steep check
```

## Next Steps

Once A2A is installed:

1. Read the [Quick Start Guide](quickstart.md)
2. Follow the [Getting Started Tutorial](guides/getting-started.md)
3. Explore [Code Examples](examples/index.md)
4. Review the [API Reference](api/index.md)

## Updating A2A

To update to the latest version:

```bash
gem update a2a
```

Or if using Bundler:

```bash
bundle update a2a
```

Or if installed from source:

```bash
cd path/to/a2a
git pull
bundle install
rake install
```

---

Installation complete! Ready to build A2A agents? Continue to the [Quick Start Guide](quickstart.md).
