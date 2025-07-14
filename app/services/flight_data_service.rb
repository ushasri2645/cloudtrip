class FlightDataService
  DATA_PATH = Rails.configuration.flight_data_file
  def self.load_unique_cities
    File.readlines(DATA_PATH).map do |line|
      fields = line.strip.split(",")
      [ fields[1], fields[2] ]
    end.flatten.uniq.sort
  end

  def self.read_flights
    File.readlines(DATA_PATH).map do |line|
      fields = line.strip.split(",")
      {
        flight_number:      fields[0],
        source:             fields[1],
        destination:        fields[2],
        departure_date:     fields[3],
        departure_time:     fields[4],
        price:              fields[5].to_f,
        economy_seats:      fields[6].to_i,
        economy_total:      fields[7].to_i,
        business_seats:     fields[8].to_i,
        business_total:     fields[9].to_i,
        first_class_seats:  fields[10].to_i,
        first_class_total:  fields[11].to_i
      }
    end
  end
end
