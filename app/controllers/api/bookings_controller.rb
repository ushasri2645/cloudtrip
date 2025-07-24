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
        return render json: { updated: false, errors: validator.errors }, status: :bad_request
      end

      booking_service = FlightBookingService.new(
        schedule: validator.schedule,
        seat: validator.seat,
        passengers: params[:passengers].to_i
      )
      bookingResult = booking_service.book_flight

      if bookingResult[:success]
        render json: { updated: true, message: bookingResult[:message], data: bookingResult[:data] }, status: :ok
      else
        render json: { updated: false, error: bookingResult[:message] }, status: bookingResult[:status] || :unprocessable_entity
      end
    end

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
  end
end
