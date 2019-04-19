Rails.application.routes.draw do
  root "locations#index"
  resources :locations, only: :index
  # resources :organizations
end
