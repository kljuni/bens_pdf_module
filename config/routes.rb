Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :documents, only: [ :create, :index, :destroy ] do
        member do
          post :import
          get :download
          patch :parse_result
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
