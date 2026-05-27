class CreateNutritionists < ActiveRecord::Migration[7.2]
  def change
    create_table :nutritionists do |t|
      t.string :name, null: false
      t.string :email

      t.timestamps
    end

    add_index :nutritionists, :email, unique: true, where: "email IS NOT NULL"
  end
end
