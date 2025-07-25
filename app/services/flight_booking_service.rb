class FlightBookingService
  def initialize(schedule:, seat:, passengers:)
    @schedule = schedule
    @seat = seat
    @passengers = passengers
  end

  def book_flight
    @seat.with_lock do
      if @seat.available_seats < @passengers
        return error("No seats available", 409)
      end

      @seat.update!(available_seats: @seat.available_seats - @passengers)
    end
    success("Booking successful", @seat)
    rescue ActiveRecord::ActiveRecordError => e
    error("Booking failed: #{e.message}", 500)
  end

  private

  def error(message, status)
    { success: false, message: message, status: status }
  end

  def success(message, record)
    { success: true, message: message, status: 200, data: record }
  end
end
