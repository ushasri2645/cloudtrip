require 'rails_helper'

RSpec.describe "Api::Airports", type: :request do
  describe "GET get /api/cities" do
    before(:all) do
      Airport.delete_all
      @airport1 = Airport.create!(city: "Delhi", code: "DEL")
      @airport2 = Airport.create!(city: "Mumbai", code: "BOM")
    end

    after(:all) do
      Airport.delete_all
    end

    it "returns a list of distinct sorted cities" do
      get "/api/cities"

      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["cities"]).to eq([ "Delhi", "Mumbai" ])
    end
  end
end
