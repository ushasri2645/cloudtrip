namespace :seed do
  desc "Seed Airports, Flights, FlightClasses, and Pricings from flat_flight_records_100.txt"
  task flights_all: :environment do
    file_path = Rails.root.join("lib/tasks/seed_file.txt")
    unless File.exist?(file_path)
      puts "❌ File not found: #{file_path}"
      next
    end

    puts "🚀 Seeding from #{file_path}..."

    lines = File.readlines(file_path).map(&:strip)
    headers = lines.shift.split(",")

    flights_cache = {}

    lines.each_with_index do |line, index|
      values = line.split(",")
      row = Hash[headers.zip(values)]

      city        = row["city"]
      code        = row["code"]
      flight_no   = row["flight_number"]
      source_id   = row["source_id"]
      dest_id     = row["destination_id"]
      departure   = row["departure_datetime"]
      arrival     = row["arrival_datetime"]
      total_seats = row["total_seats"]
      price       = row["price"]

      class_name  = row["class_name"]
      seat_class  = row["seat_class_id"]
      class_total = row["class_total_Seats"]
      class_avail = row["class_available_seats"]
      multiplier  = row["multiplier"]

      seat_class_id = row["seat_class_id"]
        seat_class = SeatClass.find_by(id: seat_class_id)

      source_airport = Airport.find_or_create_by(id: source_id) do |a|
        a.city = city
        a.code = code
      end

      destination_airport = Airport.find_or_create_by(id: dest_id) do |a|
        a.city = city
        a.code = code
      end

      flight_key = "#{flight_no}-#{source_id}-#{dest_id}"

      flight = flights_cache[flight_key] ||= Flight.find_or_create_by(
        flight_number: flight_no,
        source_id: source_id,
        destination_id: dest_id,
        departure_datetime: departure,
        arrival_datetime: arrival
      ) do |f|
        f.total_seats = total_seats
        f.price = price
      end

      flight_class = FlightSeat.find_or_create_by(
        flight_id: flight.id,
        seat_class_id: seat_class
      ) do |fc|
        fc.total_seats = class_total
        fc.available_seats = class_avail
      end

      ClassPricing.find_or_create_by(
        flight: flight,
        seat_class: seat_class
      ) do |p|
        p.multiplier = multiplier
      end
    end

    puts "✅ Seeding complete!"
  end
end
