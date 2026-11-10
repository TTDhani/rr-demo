# Capistrano configuration

lock "~> 3.20.1"

set :application, "rr-demo"
set :repo_url, "https://github.com/TTDhani/rr-demo.git"
set :branch, "main"
set :deploy_to, "/var/www/rr-demo"

append :linked_dirs,
  "log",
  "tmp/pids",
  "tmp/cache",
  "tmp/sockets",
  "storage"

set :keep_releases, 5

# Pass environment variables to remote Capistrano commands.
# Values are supplied by Jenkins Credentials.
set :default_env, {
  "RAILS_ENV" => "production",
  "SECRET_KEY_BASE" => ENV.fetch("SECRET_KEY_BASE"),
  "DB_HOST" => ENV.fetch("DB_HOST"),
  "DB_PORT" => ENV.fetch("DB_PORT", "5432"),
  "DB_NAME" => ENV.fetch("DB_NAME"),
  "DB_USERNAME" => ENV.fetch("DB_USERNAME"),
  "DB_PASSWORD" => ENV.fetch("DB_PASSWORD")
}
