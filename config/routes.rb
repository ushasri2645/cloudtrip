Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "flights#index"

  post "flights/search", to: "flights#search"
  get "flights/search", to: "flights#search"
  post "flights/book", to: "flights#book"

  namespace :api do
    get "cities", to: "flights#cities"
    post "flights", to: "flights#search"
    post "book", to: "flights#book"
  end
end
