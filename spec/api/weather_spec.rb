require 'rails_helper'

RSpec.describe Weather::API do
  include Rack::Test::Methods

  def app
    Weather::API
  end

  let(:current_response) do
    VCR.use_cassette('weather_current', record: :once) do
      location = 294021
      apikey = Rails.application.credentials.weather_api[:apikey]
      url = URI("http://dataservice.accuweather.com/currentconditions/v1/#{location}?apikey=#{apikey}")
      response = Net::HTTP.get(url)
      weather_data = JSON.parse(response)
    end
  end

  let(:historical_response) do
    VCR.use_cassette('weather_historical', record: :once) do
      location = 294021
      apikey = Rails.application.credentials.weather_api[:apikey]
      url = URI("http://dataservice.accuweather.com/currentconditions/v1/#{location}/historical/24?apikey=#{apikey}")
      response = Net::HTTP.get(url)
      weather_data = JSON.parse(response)
    end
  end

  describe 'GET /current' do
    it 'return success code' do
      VCR.use_cassette('weather_current') do
        get '/weather/current'
        expect(last_response.status).to eq(200)
      end
    end

    it 'return data' do
      VCR.use_cassette('weather_current') do
        get '/weather/current'
        expect(JSON.parse(last_response.body)).to eq({"datetime" => "2023-12-26T17:22:00+03:00", "temperature" => -1.1})
      end
    end
  end

  describe 'GET /historical' do
    it 'return success code' do
      VCR.use_cassette('weather_historical') do
        get '/weather/historical'
        expect(last_response.status).to eq(200)
      end
    end

    it 'return data' do
      VCR.use_cassette('weather_historical') do
        get '/weather/historical'
        expect(JSON.parse(last_response.body).count).to eq(24)
        expect(WeatherDatum.all.count).to eq(24)
      end
    end
  end

  describe do
    before do
      weather_data = [-1.3, 0.0, 2.4, 5.5]
      Grape::Endpoint.before_each{|ep| allow(ep).to receive_message_chain(:historical_list, :map).and_return(weather_data)}
    end

    after { Grape::Endpoint.before_each nil }
  
    describe 'GET /max' do
      
      it 'return success code' do
        VCR.use_cassette('weather_historical') do
          get '/weather/historical/max'
          expect(last_response.status).to eq(200)
        end
      end

      it 'return max' do
        get '/weather/historical/max'
        expect(last_response.body).to eq("5.5")
      end
    end

    describe 'GET /min' do
      it 'return success code' do
        VCR.use_cassette('weather_historical') do
          get '/weather/historical/min'
          expect(last_response.status).to eq(200)
        end
      end

      it 'return min' do
        get '/weather/historical/min'
        expect(last_response.body).to eq("-1.3")
      end
    end

    describe 'GET /avg' do
      it 'return success code' do
        VCR.use_cassette('weather_historical') do
          get '/weather/historical/avg'
          expect(last_response.status).to eq(200)
        end
      end

      it 'return avg' do
        get '/weather/historical/avg'
        expect(last_response.body).to eq("1.7")
      end
    end
  end

  describe 'GET /by_time' do
    before { WeatherDatum.create(datetime: "2023-12-26T21:00:00.000+03:00".to_datetime, temperature: 1.3) }
    let(:time){ Time.parse("2023-12-26T21:00:00.000+03:00").to_i }

    it 'return success code', focus: true do
      get "/weather/by_time?timestamp=#{time}"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({"data" => "2023-12-26T21:00:00.000+03:00", "temperature" => 1.3})
    end

    it 'return error code', focus: true do
      get '/weather/by_time?timestamp=12235'
      expect(last_response.status).to eq(404)
    end
  end

  describe 'GET /health' do
    it 'return success code' do
      get '/weather/health'
      expect(last_response.status).to eq(200)
    end
  end
end
