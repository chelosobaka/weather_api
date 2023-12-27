require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

scheduler.every '1h' do
  WeatherDatum.parse.delay
end
