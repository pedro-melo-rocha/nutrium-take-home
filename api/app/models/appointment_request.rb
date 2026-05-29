class AppointmentRequest < ApplicationRecord
  # `canceled` covers two cases: superseded by a newer pending from the same
  # guest, OR auto-killed because another request was accepted on an
  # overlapping slot. See DECISIONS.md (Data section).
  STATUSES = %w[pending accepted rejected canceled].freeze
  enum :status, STATUSES.index_with(&:itself), default: "pending"

  belongs_to :nutritionist
  belongs_to :service

  EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP

  validates :guest_name, presence: true, length: { maximum: 255 }
  validates :guest_email,
    presence: true,
    format: { with: EMAIL_REGEX },
    length: { maximum: 255 }
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :starts_at_must_be_future, on: :create
  validate :ends_after_starts
  validate :service_belongs_to_nutritionist

  before_validation :normalize_guest_email
  before_validation :assign_nutritionist_from_service
  before_validation :assign_ends_at_from_service

  private

  def normalize_guest_email
    self.guest_email = guest_email&.strip&.downcase.presence
  end

  # Denormalized for the GiST exclusion expression. Kept in sync from service.
  def assign_nutritionist_from_service
    self.nutritionist_id ||= service&.nutritionist_id
  end

  # `ends_at` is a snapshot at create-time. Service-duration changes must not
  # shift past bookings — accepted appointments are contracts.
  def assign_ends_at_from_service
    return if ends_at.present?
    return if starts_at.blank? || service.blank? || service.duration_minutes.blank?

    self.ends_at = starts_at + service.duration_minutes.minutes
  end

  def starts_at_must_be_future
    return if starts_at.blank?

    errors.add(:starts_at, "must be in the future") if starts_at <= Time.current
  end

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, "must be after starts_at") if ends_at <= starts_at
  end

  def service_belongs_to_nutritionist
    return if service.blank? || nutritionist_id.blank?

    if service.nutritionist_id != nutritionist_id
      errors.add(:service, "must belong to the chosen nutritionist")
    end
  end
end
