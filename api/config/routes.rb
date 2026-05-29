Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions,
  # otherwise 500. Used by load balancers, Docker healthchecks, uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :nutritionists, only: [:index] do
        # Nutritionist's request queue (for the requests page in P6).
        resources :appointment_requests, only: [:index], module: :nutritionists
      end

      resources :appointment_requests, only: [:create, :update] do
        collection do
          # Frontend UX: before submitting a new request, look up whether the
          # guest already has an active (pending or accepted) one. If so, the
          # frontend can show a "cancel X and proceed?" confirmation.
          get :lookup
        end
      end
    end
  end
end
