Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "meetups#new"
  get "meet", to: "meetups#show", as: :meet
  resources :stations, only: :index
  get "places/:group_code", to: "places#show", as: :places

  get "saved", to: "saved#index", as: :saved
  get "recent", to: "recents#index", as: :recent
  get "you", to: "profiles#show", as: :you
  resource :home_station, only: [:update, :destroy], path: "you/home"
end
