require 'net/http'

module Weather
  class API < Grape::API
    format :json

    helpers do
      def location
        #moscow
        294021
      end

      def apikey
        Rails.application.credentials.weather_api[:apikey]
      end

      def get_weather_data(url)
        response = Net::HTTP.get(url)
        weather_data = JSON.parse(response)
      end

      def historical_list
        #if we have records in db by 24 hours, then to take historical from db
        #else to take historical from api and write to db missed data
        #this method will return [{datetime: datetime, temperature: temperature}x24]
        if WeatherDatum.has_history?
          WeatherDatum.get_history.map do |data| 
            { datetime: data.datetime.in_time_zone('Europe/Moscow'), temperature: data.temperature }
          end
        else
          url = URI("http://dataservice.accuweather.com/currentconditions/v1/#{location}/historical/24?apikey=#{apikey}")
          weather_data = get_weather_data(url)
          WeatherDatum.add_missing_entries(weather_data)
          weather_data.map do |data|
            { 
              datetime: (data['LocalObservationDateTime'].to_datetime + 30.minutes).beginning_of_hour, 
              temperature: data['Temperature']['Metric']['Value'].to_f 
            }
          end
        end
      end
    end

    rescue_from :all do
      error!({ "error" => "Failed to get weather data" }, 500)
    end

    resource :weather do
      desc 'Current temperature'
      get :current do
        url = URI("http://dataservice.accuweather.com/currentconditions/v1/#{location}?apikey=#{apikey}")
        data = get_weather_data(url).first
        { datetime: data['LocalObservationDateTime'], temperature: data['Temperature']['Metric']['Value'].to_f }
      end

      resource :historical do
        desc 'Temperatures for the last 24 hours'
        get do
          historical_list
        end

        desc 'Maximum temperature for the last 24 hours'
        get :max do
          temperatures = historical_list.map { |data| data['Temperature']['Metric']['Value'].to_f }
          temperatures.max
        end

        desc 'Minimum temperature for the last 24 hours'
        get :min do
          temperatures = historical_list.map { |data| data['Temperature']['Metric']['Value'].to_f }
          temperatures.min
        end

        desc 'Average temperature for the last 24 hours'
        get :avg do
          temperatures = historical_list.map { |data| data['Temperature']['Metric']['Value'].to_f }
          (temperatures.sum / temperatures.size).round(1)
        end
      end

      desc 'Find temperature closest to the given timestamp'
      params do
        requires :timestamp, type: Integer
      end

      get :by_time do
        time = (Time.at(params[:timestamp]) + 30.minutes).beginning_of_hour
        data = WeatherDatum.find_by(datetime: time)
        if data
          { data: data.datetime.in_time_zone('Europe/Moscow'), temperature: data.temperature }
        else 
          error!('Temperature not found', 404)
        end
      end

      desc 'Health status'
      get :health do
        { status: 'OK' }
      end
    end
  end
end