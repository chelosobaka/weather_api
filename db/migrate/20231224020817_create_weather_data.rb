class CreateWeatherData < ActiveRecord::Migration[6.1]
  def change
    create_table :weather_data do |t|
      t.datetime :datetime
      t.float :temperature

      t.timestamps
    end
  end
end
