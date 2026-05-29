FactoryBot.define do
  factory :nutritionist do
    sequence(:name)  { |n| "Nutritionist #{n}" }
    sequence(:email) { |n| "nutri#{n}@example.com" }
    title { "Dietitian" }
    sequence(:license_number) { |n| "PT-#{1000 + n}" }
    photo_url { "https://example.com/avatar.png" }
  end
end
