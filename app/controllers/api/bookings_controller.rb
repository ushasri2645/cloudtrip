module Api
  class BookingsController < ApplicationController
    def booking
      flight_number, class_type, passengers = extract_booking_params

      return render_missing_flight_number if flight_number.blank?

      flight = find_flight(flight_number)
      return render_not_found("Requested flight not found") unless flight

      seat_class = find_seat_class(class_type)
      return render_not_found("Seat class '#{class_type}' not found") unless seat_class

      flight_seat = find_flight_seat(flight, seat_class)
      return render_not_found("Seat info not available for #{class_type.titleize}") unless flight_seat

      process_booking(flight_seat, passengers, class_type)
    rescue StandardError => e
      render_error("Unexpected error: #{e.message}")
    end

    private

     def extract_booking_params
      flight_params = params[:flight] || {}
      flight_number = flight_params[:flight_number]
      class_type = flight_params[:class_type] || "economy"
      passengers = params[:passengers].to_i
      passengers = 1 if passengers <= 0
      [ flight_number, class_type, passengers ]
    end

    def find_flight(flight_number)
      Flight.includes(:flight_seats).find_by(flight_number: flight_number)
    end

    def find_seat_class(class_type)
      SeatClass.where("LOWER(name) = ?", class_type.downcase).first
    end

    def find_flight_seat(flight, seat_class)
      flight.flight_seats.find_by(seat_class: seat_class)
    end

    def process_booking(flight_seat, passengers, class_type)
      FlightSeat.transaction do
        flight_seat.lock!

        if flight_seat.available_seats >= passengers
          flight_seat.update!(available_seats: flight_seat.available_seats - passengers)
          render_success("Booking successful for #{passengers} #{'passenger'.pluralize(passengers)} in #{class_type.titleize} class")
        else
          render_error("Not enough seats in #{class_type.titleize}. Requested: #{passengers}, Available: #{flight_seat.available_seats}", :unprocessable_entity)
        end
      end
    end

    def render_missing_flight_number
      render_error("Missing flight_number parameter", :bad_request)
    end

    def render_not_found(message)
      render_error(message, :not_found)
    end

    def render_error(message, status = :internal_server_error)
      render json: { updated: false, error: message }, status: status
    end

    def render_success(message)
      render json: { updated: true, message: message }, status: :ok
    end
  end
end
