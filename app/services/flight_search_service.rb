class FlightSearchService
  def initialize(source, destination, date, class_type, passengers)
    @source = source
    @destination = destination
    @date = date
    @class_type = class_type
    @passengers = passengers
  end

  def search_flights
    now = Time.zone.now
    today = Time.zone.today

    flights = FlightDataService.read_flights

    matching_flights = flights.select do |flight|
      available_seats, multiplier = available_seats_and_multiplier(flight)

      next false unless valid_flight_date?(flight, now, today)
      next false unless flight[:source].casecmp?(@source) &&
                       flight[:destination].casecmp?(@destination) &&
                       flight[:departure_date] == @date &&
                       available_seats >= @passengers

      true
    end

    if matching_flights.empty?
      return { flights: [], message: "No matching flights available" }
    end

    available_flights = matching_flights.map do |flight|
      calculate_fare(flight)
    end

    { flights: available_flights, message: "Flights found" }
  end

  private

  def available_seats_and_multiplier(flight)
    [ available_seats(flight), price_multiplier ]
  end

  def available_seats(flight)
    flight[:"#{@class_type}_seats"] || 0
  end

  def price_multiplier
    {
      "economy" => 1.0,
      "business" => 1.5,
      "first_class" => 2.0
    }[@class_type] || 1.0
  end

  def total_seats(flight)
    flight[:"#{@class_type}_total"] || flight[:economy_total]
  end

  def valid_flight_date?(flight, now, today)
    return true unless Date.parse(@date) == today

    departure_str = "#{flight[:departure_date]} #{flight[:departure_time]}"
    return false unless Date._strptime(departure_str, "%Y-%m-%d %I:%M %p")

    departure_time = Time.zone.strptime(departure_str, "%Y-%m-%d %I:%M %p")
    departure_time > now
  end

  def calculate_fare(flight)
    seats_available = available_seats(flight)
    seats_total = total_seats(flight)
    base_price = flight[:price]

    dynamic_price = DynamicPricingService.calculate_price(
      base_price, seats_total, seats_available, flight[:departure_date]
    )

    multiplier = price_multiplier
    price_per_person = dynamic_price + (base_price * multiplier)
    total_fare = price_per_person * @passengers
    extra_price = price_per_person - base_price

    flight.merge(
      total_fare:        total_fare.round(2),
      price_per_seat:    dynamic_price.round(2),
      price_per_person:  price_per_person.round(2),
      base_price:        base_price.round(2),
      extra_price:       extra_price.round(2),
      class_type:        @class_type
    )
  end
end
