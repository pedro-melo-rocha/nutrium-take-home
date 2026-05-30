class AddCoordinatesToServices < ActiveRecord::Migration[7.2]
  def change
    add_column :services, :latitude, :decimal, precision: 9, scale: 6
    add_column :services, :longitude, :decimal, precision: 9, scale: 6
  end
end
