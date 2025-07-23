require 'csv'

FlightRecurrence.delete_all
FlightSchedule.delete_all
BaseFlightSeat.delete_all
SeatClass.delete_all
Flight.delete_all
Airport.delete_all

Rails.logger.debug "Seeding Airports..."
airport_map = {}
File.read("./db/data/airports.txt").each_line do |line|
  city, code = line.strip.split(',')
  airport = Airport.create!(city: city.strip, code: code.strip)
  airport_map[code.strip] = airport
end

Rails.logger.debug "Seeding Seat Classes..."
seat_class_map = {}
File.read("./db/data/seat_class.txt").each_line do |line|
  name = line.strip
  seat_class_map[name] = SeatClass.create!(name: name)
end

Rails.logger.debug "Seeding Flights..."
flight_map = {}

File.read("./db/data/flights.txt").each_line do |line|
  flight_number, source_code, destination_code, is_recurring, dep_dt, duration =
    line.strip.split(',')

  source_airport = airport_map[source_code.strip]
  dest_airport = airport_map[destination_code.strip]

  dep_date = Time.zone.parse(dep_dt).strftime('%Y-%m-%d')
  dep_time = Time.zone.parse(dep_dt).strftime('%H:%M')

  flight = Flight.create!(
    flight_number: flight_number,
    source_id: source_airport.id,
    destination_id: dest_airport.id,
    is_recurring: is_recurring.strip == 'true',
    departure_time: dep_time,
    duration_minutes: duration
  )

  flight_map[flight_number.strip] = { model: flight, dep_dt: dep_dt }

  unless is_recurring.strip == 'true'
    FlightSchedule.create!(
      flight_id: flight.id,
      flight_date: Date.parse(dep_date)
    )
  end
end

Rails.logger.debug "Seeding Flight Recurrences..."
File.read("./db/data/flight_recurrences.txt").each_line do |line|
  next if line.strip.empty?
  parts = line.strip.split(',')
  flight_number = parts.shift
  days = parts[0..-3].map(&:to_i)
  start_date = Date.parse(parts[-2])
  end_date = Date.parse(parts[-1])

  flight = flight_map[flight_number][:model]
  FlightRecurrence.create!(
    flight_id: flight.id,
    days_of_week: days,
    start_date: start_date,
    end_date: end_date
  )
end

Rails.logger.debug "Seeding Flight Seats..."
File.read("./db/data/flight_seats.txt").each_line do |line|
  next if line.strip.empty?
  parts = line.strip.split(':')
  flight_number = parts.shift
  flight = flight_map[flight_number][:model]

  (0...parts.length).step(3) do |i|
    class_name = parts[i]
    price = parts[i + 1].to_f
    total = parts[i + 2].to_i

    seat_class = seat_class_map[class_name]
    BaseFlightSeat.create!(
      flight_id: flight.id,
      seat_class_id: seat_class.id,
      price: price,
      total_seats: total
    )
  end
end

Rails.logger.debug "✅ Seeding Completed!"
