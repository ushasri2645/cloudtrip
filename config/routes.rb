Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get "cities", to: "airports#cities"
    post "flights", to: "flights#search"
    post "book", to: "bookings#booking"
  end
end
