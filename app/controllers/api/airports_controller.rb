module Api
  class AirportsController < ApplicationController
    def cities
      cities = AirportService.getCities
      render json: { cities: cities }, status: :ok
    end
  end
end
