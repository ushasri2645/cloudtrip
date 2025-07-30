class FlightBookingService
  attr_reader :validator

  def initialize(validator)
    @validator = validator
  end

  def book
    flight = find_flight
    return error("Flight not found", 404) unless flight

    schedule = flight.flight_schedules.find_by(flight_date: validator.date)
    return error("No schedule available on this date", 404) unless schedule

    seat_class = SeatClass.find_by("LOWER(name) = ?", validator.class_type.downcase.tr("_", " "))
    return error("Seat class not found", 404) unless seat_class

    seat = FlightScheduleSeat.find_by(flight_schedule_id: schedule.id, seat_class_id: seat_class.id)
    return error("No seat info for this class on the selected date", 404) unless seat

    if seat.available_seats < validator.passengers
      return error("Not enough seats", 409)
    end

    ActiveRecord::Base.transaction do
      seat.with_lock do
        seat.update!(available_seats: seat.available_seats - validator.passengers)
      end
    end

    success("Booking successful", seat)
  rescue ActiveRecord::ActiveRecordError => e
    error("Booking failed: #{e.message}", 500)
  end

  private

  def find_flight
    source_airport = Airport.find_by("LOWER(city) = ?", validator.source.downcase)
    destination_airport = Airport.find_by("LOWER(city) = ?", validator.destination.downcase)

    return nil unless source_airport && destination_airport

    Flight.find_by(
      flight_number: validator.flight_number,
      source: source_airport,
      destination: destination_airport
    )
  end

  def error(message, status)
    { success: false, message: message, status: status }
  end

  def success(message, record)
    { success: true, message: message, status: 200, data: record }
  end
end
