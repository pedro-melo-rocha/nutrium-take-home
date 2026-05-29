module AppointmentRequests
  # Nutritionist accepts a pending appointment request.
  #
  # Spec rule: "If a request is accepted, all other overlapping pending requests
  # for the professional must be automatically rejected."
  # (Our enum collapses "auto-rejected by overlap accept" into :canceled — see
  # DECISIONS.md status enum entry.)
  #
  # Behavior (inside one transaction):
  #   1. Set this request to :accepted.
  #      Postgres GiST exclusion constraint `no_overlapping_accepted` rejects
  #      this UPDATE if another accepted request already overlaps this slot for
  #      the same nutritionist — that's the race-safe overlap guard.
  #   2. Find all OTHER pending requests for the same nutritionist whose time
  #      range overlaps this one, mark them :canceled (with a transition
  #      reason: "auto_canceled_by_overlap_accept", recorded on the record's
  #      updated_at; status alone is intentionally coarse).
  #
  # Idempotency:
  #   - If the record is already accepted, return success without re-touching
  #     overlaps. Callers can retry safely.
  #
  # Mailer enqueue (post-commit pattern):
  #   - Enqueues are issued AFTER `ActiveRecord::Base.transaction { }` commits,
  #     never inside the block. Enqueueing inside the txn would risk sending
  #     mail for work that gets rolled back.
  #   - Two mails fire on success:
  #       * `accepted` to the accepted request's guest
  #       * `canceled_by_overlap` to each guest whose pending request was
  #         auto-canceled by the overlap rule. Separate copy from `rejected`
  #         so we can be precise: not a personal "no", a slot conflict.
  #   - `deliver_later` enqueues an ActiveJob; retry/discard policy lives
  #     on ApplicationJob.
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
      # PG::ExclusionViolation surfaces as StatementInvalid in AR.
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

    # Issues both the acceptance mail and the overlap-cancellation mails.
    # Errors here are intentionally swallowed and logged: a transient mailer
    # outage must NOT roll back the (already-committed) state change. The
    # retry policy on ApplicationJob covers actual delivery flakiness.
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
