Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "flights#index"
  namespace :api do
    get "cities", to: "airports#cities"
    post "flights", to: "flights#search"
    post "book", to: "bookings#booking"
    post 'round_trip_booking', to: 'bookings#round_trip_booking'
  end
end
