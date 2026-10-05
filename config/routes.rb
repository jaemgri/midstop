Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "meetups#new"
  get "meet", to: "meetups#show", as: :meet
  get "stations/nearest", to: "stations#nearest", as: :nearest_station
  resources :stations, only: :index
  get "places/:group_code", to: "places#show", as: :places
  resources :saved_spots, only: [:create, :destroy], param: :group_code
  resources :saved_groups, only: [:create, :destroy]
  get "spots/:group_code", to: "spots#show", as: :spot

  get "saved", to: "saved#index", as: :saved
  get "recent", to: "recents#index", as: :recent
  delete "recent", to: "recents#clear"
  get "you", to: "profiles#show", as: :you
  resource :home_station, only: [:update, :destroy], path: "you/home"
end
