module Api
  class BookingsController < ApplicationController
    def booking
      validator = FlightBookingValidator.new(extract_booking_params(params[:flight], params[:passengers]))

      unless validator.valid?
        return render json: {
          updated: false,
          error: validator.errors.last[:message]
        }, status: validator.errors.last[:status]
      end

      result = FlightBookingService.new(validator).book

      if result[:success]
        render json: { updated: true, message: result[:message], data: result[:data] }, status: :ok
      else
        render json: { updated: false, error: result[:message] }, status: result[:status]
      end
    end

    def round_trip_booking
      bookings = params[:bookings]

      unless bookings.is_a?(Array) && bookings.size == 2
        return render json: {
          updated: false,
          error: "Both onward and return bookings must be provided"
        }, status: :bad_request
      end

      onward_validator = FlightBookingValidator.new(extract_booking_params(bookings[0]))
      return_validator = FlightBookingValidator.new(extract_booking_params(bookings[1]))

      unless onward_validator.valid?
        return render json: {
          updated: false,
          error: "Onward booking failed: #{onward_validator.errors.last[:message]}"
        }, status: onward_validator.errors.last[:status]
      end

      unless return_validator.valid?
        return render json: {
          updated: false,
          error: "Return booking failed: #{return_validator.errors.last[:message]}"
        }, status: return_validator.errors.last[:status]
      end

      onward_result = nil
      return_result = nil

      ActiveRecord::Base.transaction do
        onward_result = FlightBookingService.new(onward_validator).book
        unless onward_result[:success]
          return render json: {
            updated: false,
            error: "Onward booking failed: #{onward_result[:message]}"
          }, status: onward_result[:status]
        end

        return_result = FlightBookingService.new(return_validator).book
        unless return_result[:success]
          raise ActiveRecord::Rollback
        end
      end

      if return_result&.[](:success)
        render json: {
          updated: true,
          message: "Round trip booking successful 🎉",
          onward: onward_result[:data],
          return: return_result[:data]
        }, status: :ok
      else
        render json: {
          updated: false,
          error: "Return booking failed. Entire booking rolled back."
        }, status: return_result&.[](:status) || :unprocessable_entity
      end
    rescue => e
      render json: { updated: false, error: "Booking failed: #{e.message}" },
             status: :internal_server_error
    end

    private

    def extract_booking_params(flight_data, passengers = nil)
      return {} unless flight_data
      {
        flight_number: flight_data[:flight_number],
        class_type:    flight_data[:class_type] || "economy",
        passengers:    [ flight_data[:passengers].to_i, 1 ].max,
        source:        flight_data[:source],
        destination:   flight_data[:destination],
        date:          flight_data[:departure_date]
      }
    end
  end
end
