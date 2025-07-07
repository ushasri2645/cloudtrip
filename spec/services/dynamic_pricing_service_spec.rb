
require "rails_helper"

RSpec.describe DynamicPricingService do
  describe ".calculate_price" do
    let(:base_price) { 1000.0 }
    let(:today) { Time.zone.today }

    context "when 0–30% seats sold and flight is 20 days away" do
      it "returns base price (no date multiplier)" do
        price = described_class.calculate_price(base_price, 100, 80, (today + 20).to_s)
        expect(price).to eq(1000.0)
      end
    end

    context "when 40% seats sold and 7 days left" do
      it "returns 1.2x seat price + 2% per day from 15" do
        price = described_class.calculate_price(base_price, 100, 60, (today + 7).to_s)
        expect(price).to eq(1360.0)
      end
    end

    context "when 75% seats sold and 2 days left" do
      it "returns 1.35x seat price + 10% per day" do
        price = described_class.calculate_price(base_price, 100, 25, (today + 2).to_s)
        expect(price).to eq(1450.0)
      end
    end

    context "when 90% seats sold and flight is tomorrow" do
      it "returns 1.5x seat price + 20% date multiplier" do
        price = described_class.calculate_price(base_price, 100, 10, (today + 1).to_s)
        expect(price).to eq(1700.0)
      end
    end

    context "when total_seats is 0 (edge case)" do
      it "returns base price to avoid division by zero" do
        price = described_class.calculate_price(base_price, 0, 0, (today + 10).to_s)
        expect(price).to eq(base_price)
      end
    end

    context "when invalid date string is passed" do
      it "returns only seat-based price" do
        price = described_class.calculate_price(base_price, 100, 20, "invalid-date")
        expect(price).to eq(1350.0)
      end
    end

    context "when seats are not sold at all and flight is in 3 days" do
      it "applies only date-based increment (0% seat sold → 1.0x)" do
        price = described_class.calculate_price(base_price, 100, 100, (today + 3).to_s)
        expect(price).to eq(1240.0)
      end
    end
  end
end
