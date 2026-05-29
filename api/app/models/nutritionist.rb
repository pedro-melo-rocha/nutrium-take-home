class Nutritionist < ApplicationRecord
  has_many :services, dependent: :destroy
  has_many :appointment_requests, dependent: :destroy

  EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP

  validates :name, presence: true, length: { maximum: 255 }
  validates :email,
    allow_blank: true,
    uniqueness: { case_sensitive: false },
    format: { with: EMAIL_REGEX }

  validates :title, length: { maximum: 100 }, allow_blank: true
  validates :license_number, length: { maximum: 50 }, allow_blank: true
  validates :photo_url, length: { maximum: 500 }, allow_blank: true
  validates :bio, length: { maximum: 2000 }, allow_blank: true

  before_save :normalize_email

  private

  def normalize_email
    self.email = email&.strip&.downcase.presence
  end
end
