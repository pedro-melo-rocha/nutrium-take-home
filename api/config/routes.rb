Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :nutritionists, only: [ :index ] do
        resources :appointment_requests, only: [ :index ], module: :nutritionists
      end

      resources :appointment_requests, only: [ :create, :update ] do
        collection do
          # Frontend probes for active (pending/accepted) request before
          # submitting a new one — drives the "cancel X and proceed?" prompt.
          get :lookup
        end
      end
    end
  end
end
