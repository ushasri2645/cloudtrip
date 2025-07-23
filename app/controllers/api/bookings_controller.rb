module Api
  class BookingsController < ApplicationController
    def booking
      flight_number, class_type, passengers, source, destination, departure_date, departure_time = extract_booking_params
      params_for_service = {
        flight_number: flight_number,
        class_type: class_type,
        passengers: passengers,
        source: source,
        destination: destination,
        date: departure_date
      }

      result = FlightBookingService.new(params_for_service).book_flight

      if !result[:success]
        render json: { updated: false, error: result[:message] }, status: :unprocessable_entity
      else
        render json: {
          updated: true,
          message: "Booking successful",
          flight: result[:flight],
          seat_class: result[:seat_class]
        }, status: :ok
      end
    end

    def round_trip_booking
      bookings = params[:bookings]

      unless bookings.is_a?(Array) && bookings.size == 2
        render json: { updated: false, error: "Two bookings (onward and return) are required" }, status: :bad_request and return
      end

      return_result = nil
      onward_result = nil

      ActiveRecord::Base.transaction do
        onward_params = prepare_service_params(bookings[0])
        onward_result = FlightBookingService.new(onward_params).book_flight

        unless onward_result[:success]
          render json: {
            updated: false,
            error: "Onward booking failed: #{onward_result[:message]}"
          }, status: onward_result[:status] || :unprocessable_entity and return
        end

        return_params = prepare_service_params(bookings[1])
        return_result = FlightBookingService.new(return_params).book_flight

        unless return_result[:success]
          raise ActiveRecord::Rollback
        end

        render json: {
          updated: true,
          message: "Round trip booking successful",
          onward: onward_result[:data],
          return: return_result[:data]
        }, status: :ok and return
      end

      if return_result && !return_result[:success]
        render json: {
          updated: false,
          error: "Return booking failed: #{return_result[:message]}"
          }, status: return_result[:status] || :unprocessable_entity
      else
        render json: {
          updated: false,
          error: "Return booking failed. Entire booking rolled back."
          }, status: :unprocessable_entity
      end
    rescue => e
      render json: { updated: false, error: "Booking failed: #{e.message}" }, status: :internal_server_error
    end

    private

    def extract_booking_params
      flight_params   = params[:flight] || {}
      flight_number   = flight_params[:flight_number]
      class_type      = flight_params[:class_type] || "economy"
      passengers      = params[:passengers].to_i
      passengers      = 1 if passengers <= 0
      source          = flight_params[:source]
      destination     = flight_params[:destination]
      departure_date  = flight_params[:departure_date]
      departure_time  = flight_params[:departure_time]

      [ flight_number, class_type, passengers, source, destination, departure_date, departure_time ]
    end

    def prepare_service_params(flight_data)
      {
        flight_number: flight_data[:flight_number],
        class_type: flight_data[:class_type] || "economy",
        passengers: (flight_data[:passengers].to_i <= 0 ? 1 : flight_data[:passengers].to_i),
        source: flight_data[:source],
        destination: flight_data[:destination],
        date: flight_data[:departure_date]
      }
    end
  end
end
