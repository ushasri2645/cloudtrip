class FlightBookingValidator
  attr_reader :errors, :flight, :schedule, :seat_class, :seat, :passengers

  def initialize(params)
    @flight_number = params[:flight_number]
    @source        = params[:source]
    @destination   = params[:destination]
    @date          = params[:date]
    @class_type    = params[:class_type]
    @passengers    = params[:passengers].to_i
    @errors        = []
  end

  def valid?
    fetch_flight &&
    fetch_schedule &&
    fetch_seat_class &&
    fetch_seat &&
    check_seat_availability
  end

  private

  def fetch_flight
    source_airport = Airport.find_by("LOWER(city) = ?", @source.downcase)
    destination_airport = Airport.find_by("LOWER(city) = ?", @destination.downcase)

    return add_error("Source or destination airport not found", 404) unless source_airport && destination_airport

    @flight = Flight.find_by(
      flight_number: @flight_number,
      source: source_airport,
      destination: destination_airport
    ) || add_error("Flight not found", 404)
  end

  def fetch_schedule
    @schedule = @flight.flight_schedules.find_by(flight_date: @date.to_s) ||
                add_error("No schedule available on this date", 404)
  end

  def fetch_seat_class
    @seat_class = SeatClass.find_by("LOWER(name) = ?", @class_type.downcase.tr("_", " ")) ||
                  add_error("Seat class not found", 404)
  end

  def fetch_seat
   @seat = FlightScheduleSeat.find_by(
      flight_schedule_id: @schedule.id,
      seat_class_id: @seat_class.id
    ) || add_error("No seat info for this class on the selected date", 404)
  end

  def check_seat_availability
    return true if @seat.available_seats >= @passengers
    add_error("Not enough seats", 409)
  end

  def add_error(message, status)
    @errors << { message: message, status: status }
    nil
  end
end
