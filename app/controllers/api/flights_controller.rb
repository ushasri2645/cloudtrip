module Api
  class FlightsController < ApplicationController
    DATA_PATH = Rails.configuration.flight_data_file
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

      lines = File.readlines(DATA_PATH)
      updated_lines = []
      updated = false

      lines.each do |line|
        fields = line.strip.split(",")

        if fields[0] == flight_number
          seat_index = case class_type
          when "economy"     then 9
          when "business"    then 10
          when "first_class" then 11
          else
            return render json: { updated: false, error: "Invalid class_type: #{class_type}" }, status: :bad_request
          end

          available_seats = fields[seat_index].to_i

          if available_seats >= passengers
            fields[seat_index] = (available_seats - passengers).to_s
          else
            return render json: {
              updated: false,
              error: "Not enough seats available in #{class_type}. Requested: #{passengers}, Available: #{available_seats}"
            }, status: :unprocessable_entity
          end

          updated = true
        end

        updated_lines << fields.join(",")
      end

      if updated
        File.open(DATA_PATH, "w") do |file|
          file.puts updated_lines
        end
        render json: { updated: true, message: "Booking successful!" }, status: :ok
      else
        render json: { updated: false, error: "Some thing went wrong while booking flight." }, status: :internal_server_error
      end
    end
  end
end
