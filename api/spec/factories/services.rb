FactoryBot.define do
  factory :service do
    nutritionist
    sequence(:name)  { |n| "Service #{n}" }
    price_cents      { 5000 }
    location         { "Braga" }
    duration_minutes { 60 }
  end
end
