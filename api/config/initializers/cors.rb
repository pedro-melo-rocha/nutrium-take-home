# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Read more: https://github.com/cyu/rack-cors

# Vite dev server runs on :5173. In production this list is tightened via
# ENV["CORS_ORIGINS"] (comma-separated).
allowed_origins = ENV.fetch("CORS_ORIGINS", "http://localhost:5173").split(",").map(&:strip)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "*",
      headers: :any,
      methods: [:get, :post, :patch, :put, :delete, :options, :head],
      expose:  ["Link"],
      max_age: 600
  end
end
