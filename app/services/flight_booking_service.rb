class FlightBookingService
  def initialize(params)
    @flight_number = params[:flight_number]
    @source = params[:source]
    @destination = params[:destination]
    @date = Date.parse(params[:date])
    @class_type = params[:class_type]
    @passengers = params[:passengers].to_i
  end

  def book_flight
    source = Airport.find_by(city: @source)&.id
    destination = Airport.find_by(city: @destination)&.id
    flight = Flight.find_by(
      flight_number: @flight_number,
      source: source,
      destination: destination
    )
    return error("Flight not found", 404) unless flight

    schedule = flight.flight_schedules.find_by(flight_date: @date)
    return error("No schedule available on this date", 404) unless schedule

    seat_class = SeatClass.find_by("LOWER(name) = ?", @class_type)
    return error("Seat class not found", 404) unless seat_class

    seat = FlightScheduleSeat.find_by(
      flight_schedule_id: schedule.id,
      seat_class_id: seat_class.id
    )
    return error("No seat info for this class on the selected date", 404) unless seat

    if seat.available_seats < @passengers
      return error("No seats available", 409)
    end

    begin
      seat.with_lock do
        seat.update!(available_seats: seat.available_seats - @passengers)
      end
    rescue => e
      return error("Seat booking failed due to internal error", 500)
    end

    success("Booking successful", seat)
  end

  private

  def error(message, status)
    { success: false, message: message, status: status }
  end

  def success(message, record)
    { success: true, message: message, status: 200, data: record }
  end
end
