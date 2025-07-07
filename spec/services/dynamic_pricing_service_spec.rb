require "rails_helper"

RSpec.describe DynamicPricingService do
  describe ".calculate_price" do
    let(:base_price) { 1000.0 }

    context "when 0% to 30% seats are sold" do
      it "returns base price with 1.0x multiplier" do
        price = described_class.calculate_price(base_price, 100, 70)
        expect(price).to eq(1000.0)
      end
    end

    context "when 31% to 50% seats are sold" do
      it "returns price with 1.2x multiplier" do
        price = described_class.calculate_price(base_price, 100, 50)
        expect(price).to eq(1200.0)
      end
    end

    context "when 51% to 75% seats are sold" do
      it "returns price with 1.35x multiplier" do
        price = described_class.calculate_price(base_price, 100, 25)
        expect(price).to eq(1350.0)
      end
    end

    context "when more than 75% seats are sold" do
      it "returns price with 1.5x multiplier" do
        price = described_class.calculate_price(base_price, 100, 19)
        expect(price).to eq(1500.0)
      end
    end
  end
end
