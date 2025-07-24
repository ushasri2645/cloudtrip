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
    return error("Source or destination not found.", 400) unless source_airport && destination_airport

    flights = fetch_flights(source_airport,  destination_airport, @date)

    if flights.empty?
      if route_exists?
        return error("No available flights on this date", 200)
      else
        return error("We are not operating on this route. Sorry for the inconvenience", 404)
      end
    end

    matching_flights = []
    any_flight_with_seats=false

    flights.each do |flight|
      schedule = find_or_create_schedule(flight, @date)
      seat = find_or_create_schedule_seat(schedule, seat_class)

      if seat.available_seats >= @passengers
        base_seat = BaseFlightSeat.find_by(flight: flight, seat_class: seat_class)
        base_price = base_seat.price
        dynamic_price = DynamicPricingService.calculate_price(base_price, base_seat.total_seats, seat.available_seats, @date)
        price_per_person = base_price + dynamic_price
        total_fare = price_per_person * @passengers
        extra_price = total_fare - (base_price * @passengers)

        arrival_datetime = calculate_arrival_datetime(@date, flight.departure_time, flight.duration_minutes)
        departure_datetime = build_departure_datetime_string(@date, flight.departure_time)
        matching_flights << {
          flight_number:      flight.flight_number,
          departure_date:     departure_datetime,
          arrival_date:       arrival_datetime,
          source:             flight.source.city,
          destination:        flight.destination.city,
          class_type:         @class_type,
          base_price:         base_price.round(2),
          price_per_seat:     dynamic_price.round(2),
          price_per_person:   price_per_person.round(2),
          total_fare:         total_fare.round(2),
          extra_price:        extra_price.round(2),
          available_seats:    seat.available_seats,
          is_recurring: flight.is_recurring
        }
      end
    end
    if matching_flights.any?
      success(matching_flights, "Flights found")
    elsif any_flight_with_seats == false
      error("All seats are booked in #{@class_type.titleize} class on #{@date}", 409)
    else
      error("No flights match your search", 404)
    end
  end

  private

  def source_airport
    @source_airport ||= Airport.find_by("LOWER(city) = ?", @source)
  end

  def destination_airport
    @destination_airport ||= Airport.find_by("LOWER(city) = ?", @destination)
  end

  def seat_class
    @seat_class ||= SeatClass.find_by("LOWER(name) = ?", @class_type.downcase.strip.gsub("_", " "))
  end

  def fetch_flights(source, destination, date)
    date_obj = Date.parse(date.to_s)
    day_of_week = date_obj.wday

    flights = Flight.includes(:flight_recurrence, :flight_schedules).where(source: source, destination: destination)
    filtered_flights = []

    flights.each do |flight|
      recurrence = flight.flight_recurrence
      if recurrence.present? &&
        recurrence.days_of_week.include?(day_of_week) &&
        date_obj >= recurrence.start_date &&
        (recurrence.end_date.nil? || date_obj <= recurrence.end_date)
        filtered_flights << flight
      else
        schedule = flight.flight_schedules.find_by(flight_date: date_obj)
        if schedule.present?
          filtered_flights << flight
        end
      end
    end
    filtered_flights
  end

  def calculate_arrival_datetime(departure_date_str, departure_time_str, duration_minutes)
    departure_datetime = Time.zone.parse("#{departure_date_str} #{departure_time_str}")
    arrival_datetime = departure_datetime + duration_minutes.minutes
    arrival_datetime
  end


  def find_or_create_schedule(flight, date)
    schedule = FlightSchedule.find_by(flight: flight, flight_date: Date.parse(date.to_s))
    if schedule.nil?
      schedule = FlightSchedule.create(flight: flight, flight_date: Date.parse(date.to_s))
    end
    schedule
  end

  def find_or_create_schedule_seat(schedule, seat_class)
    seat = FlightScheduleSeat.find_by(flight_schedule: schedule, seat_class: seat_class)
    if seat.nil?
      base_seat = BaseFlightSeat.find_by(flight: schedule.flight, seat_class: seat_class)
      seat = FlightScheduleSeat.create(
        flight_schedule: schedule,
        seat_class: seat_class,
        available_seats: base_seat.total_seats,
      )
    end
    seat
  end

  def build_departure_datetime_string(date_str, time_str)
    datetime = Time.zone.parse("#{date_str} #{time_str}")
    datetime.strftime("%Y-%m-%d %H:%M:%S %z")
  end

  def route_exists?
    Flight.exists?(source: source_airport, destination: destination_airport)
  end

  def error(message, status)
    { flights: [], message: message, status: status }
  end

  def success(flights, message = "Flights found")
    { flights: flights, message: "Flights found", status: 200 }
  end
end
