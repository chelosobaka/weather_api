require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

scheduler.every '1m' do
  WeatherDatum.parse.delay
end