
lock "~> 3.20.1"

set :application, "rr-demo"
set :repo_url, "https://github.com/TTDhani/rr-demo.git"
set :branch, "main"
set :deploy_to, "/var/www/rr-demo"
set :keep_releases, 5

append :linked_dirs,
  "log", "tmp/pids", "tmp/cache", "tmp/sockets", "storage"

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

namespace :deploy do
  task :restart_puma do
    on roles(:app) do
      execute :sudo, "-n", :systemctl, :restart, "rr-demo-puma.service"

      execute :bash, "-lc", %q{
        for i in {1..12}; do
          if curl -fsS --max-time 5 http://127.0.0.1:3000/health; then
            echo "Puma is healthy."
            exit 0
          fi
          echo "Waiting for Puma ($i/12)..."
          sleep 5
        done

        echo "ERROR: Puma health check failed."
        exit 1
      }
    end
  end
end

after "deploy:symlink:release", "deploy:restart_puma"
