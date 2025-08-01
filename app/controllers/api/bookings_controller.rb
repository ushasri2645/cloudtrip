module Api
  class BookingsController < ApplicationController
    def booking
      flight_number, class_type, passengers, source, destination, departure_date, departure_time = extract_booking_params
      params = {
        flight_number: flight_number,
        class_type: class_type,
        passengers: passengers,
        source: source,
        destination: destination,
        date: departure_date
      }
      validator = FlightBookingValidator.new(params)

      unless validator.valid?
        return render json: { updated: false, error: validator.errors.last[:message] }, status: validator.errors.last[:status]
      end

      booking_result = perform_booking(validator)

      if booking_result[:success]
        render json: { updated: true, message: booking_result[:message], data: booking_result[:data] }, status: :ok
      else
        render json: { updated: false, error: booking_result[:message] }, status: booking_result[:status] || :unprocessable_entity
      end
    end

    def round_trip_booking
      bookings = params[:bookings]

      unless bookings.is_a?(Array) && bookings.size == 2
        render json: { updated: false, error: "Both onward and return bookings must be provided" }, status: :bad_request and return
      end

      onward_validator = FlightBookingValidator.new(prepare_service_params(bookings[0]))
      return_validator = FlightBookingValidator.new(prepare_service_params(bookings[1]))

      unless onward_validator.valid?
        return render json: { updated: false, error: "Onward booking failed: #{onward_validator.errors.last[:message]}" }, status: onward_validator.errors.last[:status]
      end

      unless return_validator.valid?
        return render json: { updated: false, error: "Return booking failed: #{return_validator.errors.last[:message]}" }, status: return_validator.errors.last[:status]
      end

      return_result = nil
      onward_result = nil

      ActiveRecord::Base.transaction do
        onward_result = perform_booking(onward_validator)

        unless onward_result[:success]
          render json: {
            updated: false,
            error: "Onward booking failed: #{onward_result[:message]}"
          }, status: onward_result[:status] || :unprocessable_entity and return
        end

        return_result = perform_booking(return_validator)

        unless return_result[:success]
          raise ActiveRecord::Rollback
        end

        render json: {
          updated: true,
          message: "Round trip booking successful🎉",
          onward: onward_result[:data],
          return: return_result[:data]
        }, status: :ok and return
      end

      render json: {
        updated: false,
        error: return_result ? "Return booking failed: #{return_result[:message]}" :
                               "Return booking failed. Entire booking rolled back."
      }, status: return_result&.[](:status) || :unprocessable_entity
    rescue => e
      render json: { updated: false, error: "Booking failed: #{e.message}" },
             status: :internal_server_error
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

    def perform_booking(validator)
      FlightBookingService.new(
        schedule: validator.schedule,
        seat: validator.seat,
        passengers: validator.passengers
      ).book_flight
    end
  end
end
