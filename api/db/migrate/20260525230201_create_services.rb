class CreateServices < ActiveRecord::Migration[7.2]
  def change
    create_table :services do |t|
      t.references :nutritionist, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :price_cents, null: false
      t.string :location, null: false
      t.integer :duration_minutes, null: false

      t.timestamps
    end

    add_index :services, :location
    add_check_constraint :services, "price_cents >= 0", name: "price_cents_non_negative"
    add_check_constraint :services, "duration_minutes > 0", name: "duration_minutes_positive"
  end
end
