require 'rails_helper'

RSpec.describe "Flights", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/flights/index"
      expect(response).to have_http_status(:success)
    end
  end

end
