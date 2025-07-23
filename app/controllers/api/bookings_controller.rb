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
