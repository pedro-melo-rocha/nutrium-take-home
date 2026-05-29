module AppointmentRequests
  # Create new pending appointment request.
  #
  # Spec rule: one pending per guest. We pre-cancel prior pendings inside the
  # txn; the partial unique index `index_appointment_requests_unique_pending_per_guest`
  # is the race-safe net (concurrent submits → RecordNotUnique → :concurrent_submission).
  # Accepted requests are NOT touched — the frontend dialog handles that UX.
  #
  # No submit-confirmation mail (spec only requires accept/reject notifications).
  # `after_commit_hook` kept as no-op so the contract matches Accept/Reject.
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

    # No-op: no submit-confirmation mail. Kept so a future feature plugs in cleanly.
    def after_commit_hook(_record); end
  end
end
