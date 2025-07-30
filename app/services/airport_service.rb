class AirportService
    def self.getCities
        Airport.select(:city).order(:city).pluck(:city)
    end
end
