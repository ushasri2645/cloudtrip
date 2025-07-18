class FlightSearchService
  def initialize(source, destination, date, class_type, passengers)
    @source = source.strip.downcase
    @destination = destination.strip.downcase
    @date = date.to_date
    @class_type = class_type.strip.downcase
    @passengers = passengers
  end

  def search_flights
    return error("Invalid class type", 400) unless seat_class

    unless source_airport && destination_airport
      return error("We are not serving this source and destination.", 400)
    end

    all_flights_between = fetch_all_flights_between_cities

    if all_flights_between.empty?
      return error("There are no flights operated from this source to destination.", 404)
    end

    flights_on_date = filter_by_date(all_flights_between)

    if flights_on_date.empty?
      return error("No flights available on #{@date.strftime('%d-%b-%Y')} between #{@source.titleize} and #{@destination.titleize}.", 200)
    end

    available_flights = filter_by_available_seats(flights_on_date)


    if available_flights.empty?
      return error("All flights on #{@date.strftime('%d-%b-%Y')} between #{@source.titleize} and #{@destination.titleize} are fully booked.", 409)
    end

    formatted_flights = available_flights.map { |flight| build_flight_result(flight) }
    success(formatted_flights)
  end

  private


  def seat_class
    class_type_normalized = @class_type.to_s.strip.downcase.gsub("_", " ")
    SeatClass.all.find do |sc|
      sc.name.downcase == class_type_normalized
    end
  end

  def source_airport
    @source_airport ||= Airport.find_by("LOWER(city) = ?", @source)
  end

  def destination_airport
    @destination_airport ||= Airport.find_by("LOWER(city) = ?", @destination)
  end


  def fetch_all_flights_between_cities
    Flight.includes(:flight_seats, :class_pricings, :source, :destination)
          .where(source: source_airport, destination: destination_airport)
  end

  def filter_by_date(flights)
    flights.select { |f| f.departure_datetime.to_date == @date }
  end

  def filter_by_available_seats(flights)
    now = Time.zone.now
    today = Time.zone.today

    flights.select do |flight|
      seat = find_seat(flight)
      seat && seat.available_seats >= @passengers && valid_today_flight?(flight, now, today)
    end
  end

  def find_seat(flight)
    flight.flight_seats.find { |fs| fs.seat_class_id == seat_class.id }
  end

  def find_pricing(flight)
    flight.class_pricings.find { |cp| cp.seat_class_id == seat_class.id }
  end

  def valid_today_flight?(flight, now, today)
    return true unless @date == today
    flight.departure_datetime > now
  end

  def calculate_dynamic_price(flight, seat)
    DynamicPricingService.calculate_price(
      flight.price,
      seat.total_seats,
      seat.available_seats,
      flight.departure_datetime.to_date
    )
  end

  def build_flight_result(flight)
    seat = find_seat(flight)
    pricing = find_pricing(flight)
    base_price = flight.price
    multiplier = pricing&.multiplier || 1.0

    dynamic_price = calculate_dynamic_price(flight, seat)
    price_per_person = dynamic_price + (base_price * multiplier)
    total_fare = price_per_person * @passengers
    extra_price = price_per_person - base_price

    {
      flight_number:      flight.flight_number,
      departure_date: flight.departure_datetime,
      arrival_date:   flight.arrival_datetime,
      source:             flight.source.city,
      destination:        flight.destination.city,
      class_type:         @class_type,
      base_price:         base_price.round(2),
      price_per_seat:     dynamic_price.round(2),
      price_per_person:   price_per_person.round(2),
      total_fare:         total_fare.round(2),
      extra_price:        extra_price.round(2),
      available_seats:    seat.available_seats
    }
  end

  def error(message, status)
    { flights: [], message: message, status: status }
  end

  def success(flights)
    { flights: flights, message: "Flights found", status: 200 }
  end
end
