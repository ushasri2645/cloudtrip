module Api
  class FlightsController < ApplicationController
    def cities
      cities = FlightDataService.load_unique_cities
      render json: { cities: cities }, status: :ok
    end

    def search
      validator = FlightSearchValidator.new(params)

      unless validator.valid?
        return render json: { errors: validator.errors }, status: :bad_request
      end

      search_service = FlightSearchService.new(
        params[:source], params[:destination], params[:date],
        validator.class_type, validator.passengers
      )

      search_results = search_service.search_flights

      render json: {
        flights: search_results[:flights],
        message: search_results[:message]
      }, status: :ok
    end
  end
end
