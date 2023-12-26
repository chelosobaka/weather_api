class WeatherDatum < ApplicationRecord

  before_validation :round_datetime
  validates :datetime, uniquenessexit: true

  scope :get_history, -> { where(datetime: 24.hours.ago.beginning_of_hour..DateTime.now.beginning_of_hour).order(datetime: :desc) }

  def self.has_history?
    self.where(datetime: 24.hours.ago.beginning_of_hour..DateTime.now.beginning_of_hour).count >= 24
  end

  def self.add_missing_entries(api_historical)
    db_weather_list = self.where(datetime: 24.hours.ago.beginning_of_hour..DateTime.now.beginning_of_hour).pluck(:datetime)
    
    api_historical.each do |data|
      date_time = (data['LocalObservationDateTime'].to_datetime + 30.minutes).beginning_of_hour

      next if db_weather_list.include?(date_time)

      WeatherDatum.create(
        datetime: date_time, 
        temperature: data['Temperature']['Metric']['Value'].to_f
      )
    end
  end

  def self.parse
    location = "294021"
    apikey = Rails.application.credentials.weather_api[:apikey]

    url = URI("http://dataservice.accuweather.com/currentconditions/v1/#{location}?apikey=#{apikey}")
    response = Net::HTTP.get(url)
    data = JSON.parse(response).first
    WeatherDatum.create(
      datetime: data['LocalObservationDateTime'],
      temperature: data['Temperature']['Metric']['Value'].to_f
    )
  rescue => e
    puts "Fail: #{e}"
  end

  private

  def round_datetime
    self.datetime = (self.datetime.to_datetime + 30.minutes).beginning_of_hour
  end
end
