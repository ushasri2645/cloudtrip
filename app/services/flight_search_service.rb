  class FlightSearchService
    class InvalidSearch < StandardError; end

    def initialize(validator)
      @source      = validator.source
      @destination = validator.destination
      @departure_date = validator.parsed_date
      @class_type  = validator.class_type
      @passengers  = validator.passengers
    end

    def search
      return :invalid_class_type unless seat_class
      return :invalid_airports unless source_airport && destination_airport

      flights = recurring_flights_query + one_time_flights_query
      return route_exists? ? :no_flights_on_date : :route_not_operated if flights.empty?

      flights_with_class = flights_with_class_seats(flights)
      return :no_class_available if flights_with_class.empty?

      results = build_response_data(flights_with_class)
      results.any? ? results : :all_seats_booked
    end


    private
    def source_airport
      @source_airport ||= Airport.find_by("LOWER(city) = ?", @source)
    end

    def destination_airport
      @destination_airport ||= Airport.find_by("LOWER(city) = ?", @destination)
    end

    def seat_class
      @seat_class ||= SeatClass.find_by("LOWER(name) = ?", @class_type.tr("_", " "))
    end

    def recurring_flights_query
      weekday = @departure_date.wday

      Flight.joins(:flight_recurrence)
            .where(source: source_airport, destination: destination_airport)
            .where("ARRAY[?]::int[] && flight_recurrences.days_of_week", weekday)
            .where("flight_recurrences.start_date <= ? AND (flight_recurrences.end_date IS NULL OR flight_recurrences.end_date >= ?)", @departure_date, @departure_date)
    end

    def one_time_flights_query
      Flight.joins(:flight_schedules)
            .where(source: source_airport, destination: destination_airport)
            .where(flight_schedules: { flight_date: @departure_date })
    end

    def flights_with_class_seats(flights)
      flight_ids = flights.pluck(:id)

      valid_ids = BaseFlightSeat
                    .where(seat_class_id: seat_class.id, flight_id: flight_ids)
                    .distinct
                    .pluck(:flight_id)

      Flight.where(id: valid_ids)
    end


    def build_response_data(flights)
      flights.each_with_object([]) do |flight, results|
        schedule = FlightSchedule.find_or_create_by(flight: flight, flight_date: @departure_date)
        seat     = find_or_create_seat(schedule)

        next unless seat && seat.available_seats >= @passengers

        pricing = calculate_price(flight, seat)
        results << format_flight_response(flight, seat, pricing)
      end
    end

    def find_or_create_seat(schedule)
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

    def calculate_price(flight, seat)
      base_seat = BaseFlightSeat.find_by(flight: flight, seat_class: seat_class)
      base_price = base_seat.price
      dynamic_price = DynamicPricingService.calculate_price(
        base_price, base_seat.total_seats, seat.available_seats, @departure_date
      )

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

    def format_flight_response(flight, seat, pricing)
      departure_time = Time.zone.parse("#{@departure_date} #{flight.departure_time}")
      arrival_time = departure_time + flight.duration_minutes.minutes

      recurrence = flight.flight_recurrence&.days_of_week
      recurrence_text = recurrence ? readable_days(recurrence) : "One-time flight"

      {
        flight_number:    flight.flight_number,
        departure_date:   departure_time.strftime("%Y-%m-%d %H:%M:%S %z"),
        arrival_date:     arrival_time,
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
        recurrence_days:  recurrence_text
      }
    end

    def readable_days(days)
      return "Everyday" if days.sort == (0..6).to_a
      Date::DAYNAMES.values_at(*days).pluck(0).join(" ")
    end
     
    def route_exists?
      Flight.exists?(source: source_airport, destination: destination_airport)
    end
  end
