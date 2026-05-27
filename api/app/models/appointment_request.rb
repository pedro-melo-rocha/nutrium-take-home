class AppointmentRequest < ApplicationRecord
  # State machine:
  #   pending  -> initial state on guest submit
  #   accepted -> nutritionist accepted (terminal)
  #   rejected -> nutritionist rejected (terminal)
  #   canceled -> superseded by a newer pending from the same guest, OR
  #               auto-killed because another request was accepted on an
  #               overlapping slot. (See DECISIONS.md P1a-004.)
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

  scope :pending_for_email, ->(email) {
    pending.where(guest_email: email&.downcase)
  }

  scope :pending_for_nutritionist, ->(nutritionist_id) {
    pending.where(nutritionist_id: nutritionist_id)
  }

  scope :overlapping, ->(nutritionist_id, range_start, range_end) {
    where(nutritionist_id: nutritionist_id)
      .where("tstzrange(starts_at, ends_at) && tstzrange(?, ?)", range_start, range_end)
  }

  private

  def normalize_guest_email
    self.guest_email = guest_email&.strip&.downcase.presence
  end

  # Denormalized nutritionist_id is kept in sync with service.nutritionist_id.
  # See DECISIONS.md P1a-003 for why this column exists.
  def assign_nutritionist_from_service
    self.nutritionist_id ||= service&.nutritionist_id
  end

  # ends_at is a snapshot of service.duration_minutes at create time. It does
  # NOT update if the service definition later changes. See DECISIONS.md P1a-002.
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
