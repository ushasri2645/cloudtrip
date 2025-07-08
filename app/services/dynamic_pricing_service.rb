class DynamicPricingService
  def self.calculate_price(base_price, total_seats, available_seats, flight_date_str)
    seats_sold = total_seats - available_seats
    seat_ratio = seats_sold.to_f / total_seats

    seat_multiplier =
      if seat_ratio <= 0.3
        0.0
      elsif seat_ratio <= 0.5
        0.2
      elsif seat_ratio <= 0.75
        0.35
      else
        0.5
      end

    seat_based_dynamic_price = base_price * seat_multiplier
    date_based_dynamic_price = 0.0
    flight_date = Date.parse(flight_date_str) rescue nil
    if flight_date
      days_left = (flight_date - Time.zone.today).to_i
      if days_left <= 15 && days_left >= 3
        date_based_dynamic_price = base_price * (0.02 * (15 - days_left))
      elsif days_left < 3  && days_left >= 0
        date_based_dynamic_price = base_price * (0.10 * (3 - days_left))
      end
    end
    final_price = seat_based_dynamic_price + date_based_dynamic_price
    final_price
  end
end
