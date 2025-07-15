class FlightDataService
  FLIGHTS_DATA_PATH = Rails.configuration.flights_file
  SEATS_DATA_PATH   = Rails.configuration.seats_file

  class << self
    def read_flights
      flights_mtime = File.mtime(FLIGHTS_DATA_PATH).to_i
      seats_mtime   = File.mtime(SEATS_DATA_PATH).to_i

      static_flights = Rails.cache.fetch("flights_static_data_#{flights_mtime}") do
        load_flights_data
      end

      seats_info = Rails.cache.fetch("seats_dynamic_data_#{seats_mtime}") do
        load_seats_data
      end

      static_flights.map do |flight|
        seats = seats_info[flight[:flight_number]]
        next unless seats

        flight.merge(seats)
      end.compact
    end

    def update_seat_availability(flight_number, class_type, passengers)
      updated = false
      updated_lines = []

      File.readlines(SEATS_DATA_PATH).each do |line|
        fields = line.strip.split(",")

        if fields[0] == flight_number
          seat_index = case class_type
                       when "economy"     then 1
                       when "business"    then 2
                       when "first_class" then 3
                       else
                         return { updated: false, error: "Invalid class_type: #{class_type}" }
                       end

          available_seats = fields[seat_index].to_i

          if available_seats >= passengers
            fields[seat_index] = (available_seats - passengers).to_s
            updated = true
          else
            return {
              updated: false,
              error: "Not enough seats in #{class_type}. Requested: #{passengers}, Available: #{available_seats}"
            }
          end
        end

        updated_lines << fields.join(",")
      end

      if updated
        File.write(SEATS_DATA_PATH, updated_lines.join("\n") + "\n")
        Rails.cache.delete_matched("seats_dynamic_data_*")
        seats_mtime = File.mtime(SEATS_DATA_PATH).to_i
        Rails.cache.write("seats_dynamic_data_#{seats_mtime}", load_seats_data)

        { updated: true, message: "Booking successful!" }
      else
        { updated: false, error: "Flight not found or seat update failed" }
      end
    end

    def load_unique_cities
      read_flights.flat_map { |f| [f[:source], f[:destination]] }.uniq.sort
    end

    private

    def load_flights_data
      File.readlines(FLIGHTS_DATA_PATH).map do |line|
        fields = line.strip.split(",")

        {
          flight_number:     fields[0],
          source:            fields[1],
          destination:       fields[2],
          departure_date:    fields[3],
          departure_time:    fields[4],
          arrival_date:      fields[5],
          arrival_time:      fields[6],
          total_seats:       fields[7].to_i,
          price:             fields[8].to_f
        }
      end
    end

    def load_seats_data
      File.readlines(SEATS_DATA_PATH).each_with_object({}) do |line, hash|
        fields = line.strip.split(",")
        hash[fields[0]] = {
          economy_seats:      fields[1].to_i,
          business_seats:     fields[2].to_i,
          first_class_seats:  fields[3].to_i,
          economy_total:      fields[4].to_i,
          business_total:     fields[5].to_i,
          first_class_total:  fields[6].to_i
        }
      end
    end
  end
end
