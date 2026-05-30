Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :nutritionists, only: [ :index ] do
        resources :appointment_requests, only: [ :index, :update ], module: :nutritionists
      end

      resources :appointment_requests, only: [ :create ] do
        collection do
          get :lookup
        end
      end
    end
  end
end
