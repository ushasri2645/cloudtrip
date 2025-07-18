module Api
  class AirportsController < ApplicationController
    def cities
      cities = Airport.select(:city).distinct.order(:city).pluck(:city)
      render json: { cities: cities }, status: :ok
    end
  end
end