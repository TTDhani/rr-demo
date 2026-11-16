
# ============================================================
# CAPISTRANO CONFIGURATION
# ============================================================

lock "~> 3.20.1"

set :application, "rr-demo"
set :repo_url, "https://github.com/TTDhani/rr-demo.git"
set :branch, "main"
set :deploy_to, "/var/www/rr-demo"

# ============================================================
# LINKED DIRECTORIES
# ============================================================

append :linked_dirs,
  "log",
  "tmp/pids",
  "tmp/cache",
  "tmp/sockets",
  "storage"

# Retain the latest 5 releases
set :keep_releases, 5

# ============================================================
# APPLICATION ENVIRONMENT VARIABLES
# ============================================================

# Values are supplied through Jenkins Credentials.

set :default_env, {
  "RAILS_ENV" => "production",
  "SECRET_KEY_BASE" => ENV.fetch("SECRET_KEY_BASE"),
  "DB_HOST" => ENV.fetch("DB_HOST"),
  "DB_PORT" => ENV.fetch("DB_PORT", "5432"),
  "DB_NAME" => ENV.fetch("DB_NAME"),
  "DB_USERNAME" => ENV.fetch("DB_USERNAME"),
  "DB_PASSWORD" => ENV.fetch("DB_PASSWORD"),
  "DB_QUEUE_NAME" => ENV.fetch("DB_QUEUE_NAME"),
  "DB_CACHE_NAME" => ENV.fetch("DB_CACHE_NAME"),
  "DB_CABLE_NAME" => ENV.fetch("DB_CABLE_NAME")
}

# ============================================================
# PUMA SERVICE RESTART
# ============================================================

namespace :deploy do

  desc "Restart RR Demo Puma service after deployment"
  task :restart_puma do
    on roles(:app) do

      info "Restarting RR Demo Puma service..."

      execute :sudo, "-n", :systemctl,
        :restart, "rr-demo-puma.service"

      info "Checking Puma service status..."

      execute :sudo, "-n", :systemctl,
        :is_active, "--quiet", "rr-demo-puma.service"

      info "Puma service is active."

      info "Verifying application health endpoint..."

      execute :curl,
        "--fail",
        "--silent",
        "--show-error",
        "--max-time", "15",
        "http://127.0.0.1:3000/health"

      info "Application health check passed."

    end
  end

end

# ============================================================
# DEPLOYMENT HOOK
# ============================================================

# Execute after Capistrano switches the current symlink.
# This ensures Puma loads the newly deployed release.

after "deploy:symlink:release", "deploy:restart_puma"
