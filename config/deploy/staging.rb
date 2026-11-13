
# config/deploy/staging.rb

require "net/ssh"
require "socket"

set :stage, :staging
set :rails_env, "production"

# Use the SSH key provided by Jenkins sshagent.
# Do not require a local PEM file.

ssh_options = {
  auth_methods: %w[publickey],
  use_agent: true,
  forward_agent: false,
  non_interactive: true,
  timeout: 5
}

set :ssh_options, ssh_options

deployment_servers = [
  { host: "10.20.133.231", user: "ubuntu", roles: %w[app web db] },
  { host: "10.20.143.220", user: "ubuntu", roles: %w[app web db] }
]

reachable_count = 0

deployment_servers.each do |srv|
  host = srv[:host]

  puts "\nChecking SSH connectivity to #{host}..."

  begin
    Net::SSH.start(
      host,
      srv[:user],
      **ssh_options
    ) do |ssh|
      ssh.exec!("true")
    end

    reachable_count += 1

    server host,
      user: srv[:user],
      roles: srv[:roles],
      primary: reachable_count == 1

    puts "SUCCESS: #{host} is reachable. Added to deployment."

  rescue Net::SSH::ConnectionTimeout,
         Errno::ECONNREFUSED,
         Errno::ETIMEDOUT,
         Errno::EHOSTUNREACH,
         Errno::ENETUNREACH,
         Errno::ECONNRESET,
         SocketError => e

    puts "WARNING: Skipping #{host}"
    puts "Reason: #{e.class}: #{e.message}"

  end
end

if reachable_count.zero?
  raise "Deployment aborted: No reachable staging servers found."
end

puts "\n======================================"
puts "Reachable deployment servers: #{reachable_count}"
puts "======================================"
