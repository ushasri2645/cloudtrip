require 'rails_helper'

RSpec.describe FlightRecurrence, type: :model do
  describe "associations" do
    it { should belong_to(:flight) }
  end
end
