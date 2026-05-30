module AppointmentRequests
  class Create
    Result = AppointmentRequests::Result

    def call(params)
      record = nil

      ActiveRecord::Base.transaction do
        AppointmentRequest
          .where(guest_email: normalize_email(params[:guest_email]), status: :pending)
          .update_all(status: "rejected", updated_at: Time.current)

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

    def after_commit_hook(_record); end
  end
end
