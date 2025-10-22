#!/usr/bin/env ruby
# Demo script to run A2A client-server example
#
# This script demonstrates the complete A2A (Agent-to-Agent) protocol by:
# 1. Starting a simple echo server in the background
# 2. Running a conversation client that sends multiple messages
# 3. Cleaning up the server process when done
#
# Usage:
#   ruby run_demo.rb
#   # or
#   chmod +x run_demo.rb && ./run_demo.rb

require 'timeout'
require 'net/http'

# Configuration
SERVER_SCRIPT = File.expand_path('server/simple_sinatra_server.rb', __dir__)
CLIENT_SCRIPT = File.expand_path('client/conversation_client.rb', __dir__)
SERVER_PORT = 4567
SERVER_URL = "http://localhost:#{SERVER_PORT}"
STARTUP_TIMEOUT = 10

puts "=" * 70
puts "A2A Client-Server Demo"
puts "=" * 70
puts

# Start the server in background
puts "Starting A2A server on port #{SERVER_PORT}..."
server_pid = spawn("ruby #{SERVER_SCRIPT}",
                    out: '/tmp/a2a_server.log',
                    err: '/tmp/a2a_server.log')

# Store PID for cleanup
at_exit do
  if server_pid
    puts "\nStopping server (PID: #{server_pid})..."
    Process.kill('TERM', server_pid) rescue nil
    Process.wait(server_pid) rescue nil
    puts "Server stopped."
  end
end

# Wait for server to be ready
print "Waiting for server to start"
server_ready = false

begin
  Timeout.timeout(STARTUP_TIMEOUT) do
    loop do
      begin
        response = Net::HTTP.get_response(URI("#{SERVER_URL}/.well-known/agent.json"))
        if response.code == "200"
          server_ready = true
          break
        end
      rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL
        # Server not ready yet
      end
      print "."
      sleep 0.5
    end
  end
rescue Timeout::Error
  puts "\n\n❌ Server failed to start within #{STARTUP_TIMEOUT} seconds"
  puts "Check /tmp/a2a_server.log for errors"
  exit 1
end

puts " ✓"
puts "Server is ready!"
puts

# Run the client
puts "-" * 70
puts "Running conversation client..."
puts "-" * 70
puts

system("ruby #{CLIENT_SCRIPT}")

puts
puts "-" * 70
puts "Demo completed!"
puts
puts "Server logs available at: /tmp/a2a_server.log"
puts "=" * 70
