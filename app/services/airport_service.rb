class AirportService
    def getCities
        Airport.select(:city).order(:city).pluck(:city)
    end
end
