require 'rails_helper'

RSpec.describe "rack attack" do
  it 'rate limits for endpoint health' do
    5.times do
      get '/weather/health'
      expect(response.status).to have_http_status(:ok)
    end

    get '/weather/health'
    expect(response).to have_http_status(:too_many_requests)
    Rack::Attack.cache.store.clear
  end
end