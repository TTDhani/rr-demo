Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "/health", to: proc {
    [200, { "Content-Type" => "application/json" },
     ['{"status":"ok","application":"rr-demo"}']]
  }
end
