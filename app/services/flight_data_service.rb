class FlightDataService
  DATA_PATH = Rails.configuration.flight_data_file
  def self.load_unique_cities
    File.readlines(DATA_PATH).map do |line|
      fields = line.strip.split(",")
      [ fields[1], fields[2] ]
    end.flatten.uniq.sort
  end
end
