FactoryBot.define do
  factory :appointment_request do
    service
    nutritionist { service.nutritionist }
    sequence(:guest_name)  { |n| "Guest #{n}" }
    sequence(:guest_email) { |n| "guest#{n}@example.com" }
    starts_at { 2.days.from_now }
    # ends_at + status auto-set by model callbacks / DB default
  end
end
