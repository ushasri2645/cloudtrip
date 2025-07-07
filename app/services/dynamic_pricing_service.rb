class DynamicPricingService
  def self.calculate_price(base_price, total_seats, available_seats)
    seats_sold = total_seats - available_seats
    sold_percentage = (seats_sold.to_f / total_seats) * 100

    multiplier =
      if sold_percentage <= 30
        1.0
      elsif sold_percentage <= 50
        1.2
      elsif sold_percentage <= 75
        1.35
      else
        1.5
      end

    (base_price * multiplier).round(2)
  end
end
