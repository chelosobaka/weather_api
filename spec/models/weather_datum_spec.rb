require 'rails_helper'

RSpec.describe WeatherDatum, type: :model do
  describe '#round_datetime' do
    it 'round datetime to near hour' do
      weather_datum = WeatherDatum.create(datetime: "2023-12-26T02:27:00+03:00".to_datetime)
      expect(weather_datum.datetime.in_time_zone('Europe/Moscow')).to eq("2023-12-26T02:00:00+03:00".to_datetime)
    end
  end

  describe '.has_history?' do
    it 'return true if  24 records' do
      (0..23).each { |i| WeatherDatum.create( datetime: Time.now.beginning_of_hour - i.hour) }
      expect(WeatherDatum.has_history?).to eq(true)
    end

    it 'return false if less than 24 records' do
      (0..10).each { |i| WeatherDatum.create( datetime: Time.now.beginning_of_hour - i.hour) }
      expect(WeatherDatum.has_history?).to eq(false)
    end
  end

  describe '.add_missing_entries' do
    before do
      WeatherDatum.create(datetime: "2023-12-26T16:57:00+03:00".to_datetime)
    end

    let(:weather_array) do
      [
        {"LocalObservationDateTime"=>"2023-12-26T16:57:00+03:00", "Temperature"=>{"Metric"=>{"Value"=>-1.1}}},
        {"LocalObservationDateTime"=>"2023-12-26T15:57:00+03:00", "Temperature"=>{"Metric"=>{"Value"=>-1.1}}},
        {"LocalObservationDateTime"=>"2023-12-26T14:57:00+03:00", "Temperature"=>{"Metric"=>{"Value"=>-1.1}}}
      ]
    end

    it 'creates missing entries from API historical data' do
      expect { WeatherDatum.add_missing_entries(weather_array) }.to change{ WeatherDatum.count }.by(2)
    end
  end

  describe '.parse' do
    it 'creates a WeatherDatum from API data', focus: true do
      VCR.use_cassette('weather_current') do
        expect { WeatherDatum.parse }.to change{ WeatherDatum.count }.by(1)
      end
    end
  end
end
