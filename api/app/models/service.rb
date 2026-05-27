class Service < ApplicationRecord
  belongs_to :nutritionist
  has_many :appointment_requests, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 255 }
  validates :location, presence: true, length: { maximum: 255 }
  validates :price_cents,
    presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :duration_minutes,
    presence: true,
    numericality: { only_integer: true, greater_than: 0 }

  scope :in_location, ->(loc) {
    where("LOWER(location) = LOWER(?)", loc) if loc.present?
  }
end
