Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

Rack::Attack.throttle('current', limit: 5, period: 1) do |req|
  req.ip if req.path.match?('/weather/current') 
end

Rack::Attack.throttle('historical', limit: 5, period: 1) do |req|
  req.ip if req.path.match?('/weather/historical') 
end

Rack::Attack.throttle('min', limit: 5, period: 1) do |req|
  req.ip if req.path.match?('/weather/historical/min') 
end

Rack::Attack.throttle('max', limit: 5, period: 1) do |req|
  req.ip if req.path.match?('/weather/historical/max') 
end

Rack::Attack.throttle('avg', limit: 5, period: 1) do |req|
  req.ip if req.path.match?('/weather/historical/avg')
end

Rack::Attack.throttle('by_time', limit: 5, period: 1) do |req|
  req.ip if req.path.match?('/weather/by_time') 
end

Rack::Attack.throttle('health', limit: 5, period: 10) do |req|
  req.ip if req.path.match?('/weather/health')
end


