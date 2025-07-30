class AirportService
    def self.getCities
        cities = Airport.select(:city).distinct.order(:city).pluck(:city)
        cities
    end
end
