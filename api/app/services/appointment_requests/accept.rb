module AppointmentRequests
  class Accept
    Result = AppointmentRequests::Result

    def call(record)
      return idempotent_success(record) if record.accepted?
      return invalid_state(record)      unless record.pending?

      rejected_overlaps = []

      ActiveRecord::Base.transaction do
        record.update!(status: :accepted)

        rejected_overlaps =
          AppointmentRequest
            .pending
            .where(nutritionist_id: record.nutritionist_id)
            .where.not(id: record.id)
            .where("tstzrange(starts_at, ends_at) && tstzrange(?, ?)", record.starts_at, record.ends_at)
            .to_a

        AppointmentRequest
          .where(id: rejected_overlaps.map(&:id))
          .update_all(status: "rejected", updated_at: Time.current)
      end

      after_commit_hook(record, rejected_overlaps)
      Result.new(success: true, record: record, error_code: nil, error_message: nil)
    rescue ActiveRecord::StatementInvalid => e
      if e.cause.is_a?(PG::ExclusionViolation)
        Result.new(success: false, record: record, error_code: :overlap_conflict,
                   error_message: "Another accepted appointment overlaps this slot.")
      else
        raise
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, record: e.record, error_code: :validation_failed, error_message: e.message)
    end

    private

    def idempotent_success(record)
      Result.new(success: true, record: record, error_code: nil, error_message: nil)
    end

    def invalid_state(record)
      Result.new(success: false, record: record, error_code: :invalid_state,
                 error_message: "Cannot accept a request in status '#{record.status}'.")
    end

    def after_commit_hook(record, rejected_overlaps)
      AppointmentRequestMailer.with(request: record).accepted.deliver_later

      rejected_overlaps.each do |overlap|
        AppointmentRequestMailer.with(request: overlap).slot_unavailable.deliver_later
      end
    rescue StandardError => e
      Rails.logger.error("[AppointmentRequests::Accept] mail enqueue failed: #{e.class}: #{e.message}")
    end
  end
end
