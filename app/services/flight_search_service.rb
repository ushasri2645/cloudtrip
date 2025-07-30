class FlightSearchService
  def initialize(source, destination, date, class_type, passengers)
    @source      = source.strip.downcase
    @destination = destination.strip.downcase
    @date        = date.to_date
    @class_type  = class_type.strip.downcase
    @passengers  = passengers
  end

  def search_flights
    return error("Invalid class type", 400) unless seat_class
    return error("Source or destination not found.", 400) unless source_airport && destination_airport

    flights = fetch_flights

    if flights.empty?
      return route_exists? ? error("No available flights on this date", 200) :
                             error("We are not operating on this route. Sorry for the inconvenience", 404)
    end

    flights_with_class = flights_supporting_class(flights)
    return error("Sorry! 😔 No flights available for #{class_type_title}.", 404) if flights_with_class.empty?

    results = matching_flight_data(flights_with_class)

    results.any? ? success(results, "Flights found") :
                          error("All seats are booked in #{class_type_title} class on #{@date}", 409)
  end

  private

  def source_airport
    @source_airport ||= Airport.find_by("LOWER(city) = ?", @source)
  end

  def destination_airport
    @destination_airport ||= Airport.find_by("LOWER(city) = ?", @destination)
  end

  def seat_class
    @seat_class ||= SeatClass.find_by("LOWER(name) = ?", @class_type.gsub("_", " "))
  end

  def class_type_title
    @class_type.titleize
  end

  def fetch_flights
    date_obj = @date
    day_of_week = date_obj.wday

    Flight.includes(:flight_recurrence, :flight_schedules)
          .where(source: source_airport, destination: destination_airport)
          .select do |flight|
            recurrence = flight.flight_recurrence
            if recurrence.present?
              recurrence.days_of_week.include?(day_of_week) &&
                date_obj.between?(recurrence.start_date, recurrence.end_date || date_obj)
            else
              flight.flight_schedules.exists?(flight_date: date_obj)
            end
          end
  end

  def flights_supporting_class(flights)
    BaseFlightSeat.where(flight: flights, seat_class: seat_class).pluck(:flight_id).uniq
    flights.select { |f| f.id.in?(BaseFlightSeat.where(seat_class: seat_class).pluck(:flight_id)) }
  end

  def matching_flight_data(flights)
    flights.each_with_object([]) do |flight, result|
      schedule = find_or_create_schedule(flight)
      seat     = find_or_create_schedule_seat(schedule)
      next unless seat && seat.available_seats >= @passengers

      pricing = calculate_pricing(flight, seat)
      result << build_flight_data(flight, seat, pricing)
    end
  end

  def find_or_create_schedule(flight)
    FlightSchedule.find_or_create_by(flight: flight, flight_date: @date)
  end

  def find_or_create_schedule_seat(schedule)
    seat = FlightScheduleSeat.find_by(flight_schedule: schedule, seat_class: seat_class)
    return seat if seat

    base_seat = BaseFlightSeat.find_by(flight: schedule.flight, seat_class: seat_class)
    return nil unless base_seat

    FlightScheduleSeat.create(
      flight_schedule: schedule,
      seat_class: seat_class,
      available_seats: base_seat.total_seats
    )
  end

  def calculate_pricing(flight, seat)
    base_seat = BaseFlightSeat.find_by(flight: flight, seat_class: seat_class)
    base_price = base_seat.price
    dynamic_price = DynamicPricingService.calculate_price(base_price, base_seat.total_seats, seat.available_seats, @date)

    price_per_person = base_price + dynamic_price
    total_fare = price_per_person * @passengers

    {
      base_price: base_price,
      dynamic_price: dynamic_price,
      price_per_person: price_per_person,
      total_fare: total_fare,
      extra_price: total_fare - (base_price * @passengers)
    }
  end

  def build_flight_data(flight, seat, pricing)
    departure_datetime = Time.zone.parse("#{@date} #{flight.departure_time}")
    arrival_datetime   = departure_datetime + flight.duration_minutes.minutes

    recurrence_days = flight.flight_recurrence ? readable_days(flight.flight_recurrence.days_of_week) : "One-time flight"

    {
      flight_number:    flight.flight_number,
      departure_date:   departure_datetime.strftime("%Y-%m-%d %H:%M:%S %z"),
      arrival_date:     arrival_datetime,
      source:           flight.source.city,
      destination:      flight.destination.city,
      class_type:       @class_type,
      base_price:       pricing[:base_price].round(2),
      price_per_seat:   pricing[:dynamic_price].round(2),
      price_per_person: pricing[:price_per_person].round(2),
      total_fare:       pricing[:total_fare].round(2),
      extra_price:      pricing[:extra_price].round(2),
      available_seats:  seat.available_seats,
      is_recurring:     flight.is_recurring,
      recurrence_days:  recurrence_days
    }
  end

  def readable_days(days)
    return "Everyday" if days.sort == (0..6).to_a

    Date::DAYNAMES.values_at(*days).pluck(0).join(" ")
  end

  def route_exists?
    Flight.exists?(source: source_airport, destination: destination_airport)
  end

  def error(message, status)
    { flights: [], message: message, status: status }
  end

  def success(flights, message = "Flights found")
    { flights: flights, message: message, status: 200 }
  end
end
