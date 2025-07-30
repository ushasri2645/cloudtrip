module Api
  class FlightsController < ApplicationController
    def search
      validator = FlightSearchValidator.new(params)

      unless validator.valid?
        return render json: { errors: validator.errors }, status: :bad_request
      end

      service = FlightSearchService.new(validator)
      result = service.search

      case result
      when :invalid_class_type
        render json: { message: "Invalid class type" }, status: :bad_request

      when :invalid_airports
        render json: { message: "Source or destination not found." }, status: :bad_request

      when :route_not_operated
        render json: { message: "We are not operating on this route. Sorry for the inconvenience" }, status: :not_found

      when :no_flights_on_date
        render json: { flights: [], message: "No available flights on this date" }, status: :ok

      when :no_class_available
        render json: { message: "Sorry! 😔 No flights available for #{validator.class_type}." }, status: :not_found

      when :all_seats_booked
        render json: { message: "All seats are booked in #{validator.class_type} class on #{validator.parsed_date}" }, status: :conflict

      else
        render json: {
          flights: result,
          message: "Flights found"
        }, status: :ok
      end
    end
  end
end
