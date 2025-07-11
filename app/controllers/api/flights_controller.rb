module Api
  class FlightsController < ApplicationController
    def cities
      cities = FlightDataService.load_unique_cities
      render json: { cities: cities }
    end
  end
end
