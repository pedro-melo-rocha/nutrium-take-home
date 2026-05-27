FactoryBot.define do
  factory :nutritionist do
    sequence(:name)  { |n| "Nutritionist #{n}" }
    sequence(:email) { |n| "nutri#{n}@example.com" }
  end
end
