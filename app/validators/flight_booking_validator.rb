class FlightBookingValidator
  attr_reader :errors, :flight, :schedule, :seat_class, :seat

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
    return false unless @flight    = fetch_flight
    return false unless @schedule  = fetch_schedule
    return false unless @seat_class = fetch_seat_class
    return false unless @seat      = fetch_seat
    return false if check_seat_availability.nil?

    true
  end

  private

  def fetch_flight
     source_airport = Airport.find_by("LOWER(city) = ?", @source.downcase)
    destination_airport = Airport.find_by("LOWER(city) = ?", @destination.downcase)

    unless source_airport && destination_airport
        @errors << { message: "Source or destination airport not found", status: 404 }
        return nil
    end
    flight = Flight.find_by(
      flight_number: @flight_number,
      source: source_airport,
      destination: destination_airport
    )
    unless flight
      @errors << { message: "Flight not found", status: 404 }
      return nil
    end
    flight
  end

  def fetch_schedule
    puts "date #{@date}"
    schedule = flight.flight_schedules.find_by(flight_date: @date.to_s)
    unless schedule
      @errors << { message: "No schedule available on this date", status: 404 }
      return nil
    end
    schedule
  end

  def fetch_seat_class
    seat_class = SeatClass.find_by("LOWER(name) = ?", @class_type.downcase.tr("_", " "))
    unless seat_class
      @errors << { message: "Seat class not found", status: 404 }
      return nil
    end
    seat_class
  end

  def fetch_seat
    seat = FlightScheduleSeat.find_by(
      flight_schedule_id: @schedule.id,
      seat_class_id: @seat_class.id
    )
    unless seat
      @errors << { message: "No seat info for this class on the selected date", status: 404 }
      return nil
    end
    seat
  end

  def check_seat_availability
    if @seat.available_seats < @passengers
      @errors << { message: "Not enough seats", status: 409 }
      return nil
    end
    true
  end
end
