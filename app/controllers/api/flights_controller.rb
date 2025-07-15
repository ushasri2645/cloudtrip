module Api
  class FlightsController < ApplicationController
    FLIGHTS_DATA_PATH = Rails.configuration.flights_file
    SEATS_DATA_PATH   = Rails.configuration.seats_file

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

    def book
      unless params["flight"].present? && params["flight"]["flight_number"].present?
        return render json: { updated: false, error: "Missing flight_number parameter" }, status: :bad_request
      end

      flight_number = params["flight"]["flight_number"]
      class_type    = params["flight"]["class_type"] || "economy"
      passengers    = params["passengers"].present? ? params["passengers"].to_i : 1

      result = FlightDataService.update_seat_availability(flight_number, class_type, passengers)

       if result[:updated]
          render json: { updated: true, message: result[:message] }, status: :ok
       else
          error_message = result[:error].to_s.downcase

          status = if error_message.include?("invalid class_type")
                    :bad_request
          elsif error_message.include?("not enough seats")
                    :unprocessable_entity
          else
                    :internal_server_error
          end

          render json: { updated: false, error: result[:error] }, status: status
       end
      end
  end
end
