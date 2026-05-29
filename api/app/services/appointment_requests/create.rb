module AppointmentRequests
  # Create a new pending appointment request for a guest.
  #
  # Spec rule: "A guest can only have one pending appointment request — submitting
  # a new pending request must invalidate the existing ones from the same guest."
  #
  # Behavior:
  #   1. Inside one transaction:
  #        a. Mark any existing PENDING requests from this guest_email as :canceled.
  #           (Accepted ones are NOT touched — those are confirmed bookings; the
  #            frontend confirmation dialog handles that UX layer.)
  #        b. Insert the new pending request.
  #   2. After the transaction commits, return the persisted record.
  #
  # Race safety:
  #   - Two concurrent submits from the same email race for the partial unique
  #     index `index_appointment_requests_unique_pending_per_guest`. Postgres
  #     will reject the loser with ActiveRecord::RecordNotUnique. The caller
  #     can treat that as a retry signal.
  #
  # Mailer enqueue:
  #   - No "submitted" confirmation mail. Spec only requires notifying the guest
  #     on the nutritionist's decision (accept/reject). Adding a submit-time
  #     confirmation = scope creep + extra noise in the guest's inbox.
  #   - The after_commit_hook stub is kept so the contract matches Accept and
  #     Reject, and so a future "submit confirmation" feature plugs in cleanly.
  class Create
    Result = AppointmentRequests::Result

    def call(params)
      record = nil

      ActiveRecord::Base.transaction do
        AppointmentRequest
          .where(guest_email: normalize_email(params[:guest_email]), status: :pending)
          .update_all(status: "canceled", updated_at: Time.current)

        record = AppointmentRequest.new(params)
        record.save!
      end

      after_commit_hook(record)
      Result.new(success: true, record: record, error_code: nil, error_message: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, record: e.record, error_code: :validation_failed, error_message: e.message)
    rescue ActiveRecord::RecordNotUnique
      Result.new(success: false, record: nil, error_code: :concurrent_submission,
                 error_message: "Another submission for this email is in flight; please retry.")
    end

    private

    def normalize_email(email)
      email.to_s.strip.downcase.presence
    end

    # Intentional no-op: no submit-confirmation mail (out of spec, see comments above).
    def after_commit_hook(_record); end
  end
end
