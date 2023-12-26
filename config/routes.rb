Rails.application.routes.draw do
  mount Weather::API => '/'
end
