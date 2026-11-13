
# config/deploy/staging.rb

require "net/ssh"
require "socket"

set :stage, :staging
set :rails_env, "production"

ssh_key = File.expand_path("~/.ssh/demand.pem")

unless File.file?(ssh_key)
  raise "SSH private key not found: #{ssh_key}"
end

set :ssh_options, {
  auth_methods: %w[publickey],
  keys: [ssh_key],
  forward_agent: false,
  non_interactive: true,
  timeout: 5
}

deployment_servers = [
  "10.20.133.231",
  "10.20.143.220"
]

reachable_count = 0

deployment_servers.each do |host|
  puts "\nChecking SSH connectivity to #{host}..."

  begin
    Net::SSH.start(
      host,
      "ubuntu",
      **fetch(:ssh_options).merge(timeout: 5)
    ) do |ssh|
      ssh.exec!("true")
    end

    reachable_count += 1

    server host,
      user: "ubuntu",
      roles: %w[app web db],
      primary: reachable_count == 1

    puts "SUCCESS: #{host} is reachable and added to deployment."

  rescue Net::SSH::ConnectionTimeout,
         Errno::ECONNREFUSED,
         Errno::ETIMEDOUT,
         Errno::EHOSTUNREACH,
         Errno::ENETUNREACH,
         Errno::ECONNRESET,
         SocketError => e

    puts "WARNING: Skipping #{host} - SSH unavailable: #{e.class}: #{e.message}"
  end
end

if reachable_count.zero?
  raise "Deployment aborted: No reachable staging servers found."
end

puts "\n#{reachable_count} staging server(s) available for deployment."
