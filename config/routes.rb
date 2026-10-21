Rails.application.routes.draw do
  root "locations#index"
  resources :locations, only: :index

  get "up" => "rails/health#show", :as => :rails_health_check
end
