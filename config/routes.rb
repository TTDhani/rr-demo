Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "/health", to: proc {
    [200, { "Content-Type" => "application/json" },
     ['{"status":"ok","application":"rr-demo"}']]
  }

  root to: proc {
    [200, { "Content-Type" => "text/html" }, [
      '<html><body style="font-family:Arial;text-align:center;padding:80px;">' \
      '<h1>Welcome to RR Demo Application</h1>' \
      '<p>Rails application is running successfully on AWS!</p>' \
      '</body></html>'
    ]]
  }
end
