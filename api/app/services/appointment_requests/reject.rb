module AppointmentRequests
  class Reject
    Result = AppointmentRequests::Result

    def call(record)
      return idempotent_success(record) if record.rejected?
      return invalid_state(record)      unless record.pending?

      ActiveRecord::Base.transaction do
        record.update!(status: :rejected)
      end

      after_commit_hook(record)
      Result.new(success: true, record: record, error_code: nil, error_message: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, record: e.record, error_code: :validation_failed, error_message: e.message)
    end

    private

    def idempotent_success(record)
      Result.new(success: true, record: record, error_code: nil, error_message: nil)
    end

    def invalid_state(record)
      Result.new(success: false, record: record, error_code: :invalid_state,
                 error_message: "Cannot reject a request in status '#{record.status}'.")
    end

    def after_commit_hook(record)
      AppointmentRequestMailer.with(request: record).rejected.deliver_later
    rescue StandardError => e
      Rails.logger.error("[AppointmentRequests::Reject] mail enqueue failed: #{e.class}: #{e.message}")
    end
  end
end
