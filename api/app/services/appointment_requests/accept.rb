module AppointmentRequests
  # Nutritionist accepts a pending request. Idempotent on already-accepted.
  #
  # In one transaction:
  #   - Flip status to :accepted. Postgres GiST exclusion `no_overlapping_accepted`
  #     rejects the UPDATE if another accepted request already overlaps this slot
  #     for the same nutritionist — race-safe overlap guard.
  #   - Cancel all OTHER pending requests for this nutritionist whose time range
  #     overlaps. (Spec says "automatically rejected"; we collapse into :canceled
  #     so :rejected stays a personal "no". See DECISIONS.md.)
  class Accept
    Result = AppointmentRequests::Result

    def call(record)
      return idempotent_success(record) if record.accepted?
      return invalid_state(record)      unless record.pending?

      canceled_overlaps = []

      ActiveRecord::Base.transaction do
        record.update!(status: :accepted)

        canceled_overlaps =
          AppointmentRequest
            .pending
            .where(nutritionist_id: record.nutritionist_id)
            .where.not(id: record.id)
            .where("tstzrange(starts_at, ends_at) && tstzrange(?, ?)", record.starts_at, record.ends_at)
            .to_a

        AppointmentRequest
          .where(id: canceled_overlaps.map(&:id))
          .update_all(status: "canceled", updated_at: Time.current)
      end

      after_commit_hook(record, canceled_overlaps)
      Result.new(success: true, record: record, error_code: nil, error_message: nil)
    rescue ActiveRecord::StatementInvalid => e
      # PG::ExclusionViolation surfaces as StatementInvalid in AR — unwrap.
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

    # Mailer errors swallowed + logged: a transient mailer outage must not
    # blow up an already-committed state change. ApplicationJob owns delivery retries.
    def after_commit_hook(record, canceled_overlaps)
      AppointmentRequestMailer.with(request: record).accepted.deliver_later

      canceled_overlaps.each do |canceled|
        AppointmentRequestMailer.with(request: canceled).canceled_by_overlap.deliver_later
      end
    rescue StandardError => e
      Rails.logger.error("[AppointmentRequests::Accept] mail enqueue failed: #{e.class}: #{e.message}")
    end
  end
end
