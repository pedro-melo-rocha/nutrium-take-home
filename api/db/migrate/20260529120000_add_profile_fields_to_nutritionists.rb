class AddProfileFieldsToNutritionists < ActiveRecord::Migration[7.2]
  def change
    add_column :nutritionists, :title, :string
    add_column :nutritionists, :license_number, :string
    add_column :nutritionists, :photo_url, :string
    add_column :nutritionists, :bio, :text
  end
end
