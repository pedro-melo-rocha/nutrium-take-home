module AppointmentRequests
  # Result object returned by Create/Accept/Reject. `error_code` lets controllers
  # map to HTTP status (`:validation_failed` → 422, `:overlap_conflict` → 409,
  # `:concurrent_submission` → 409, `:invalid_state` → 409) without rescue-forests.
  Result = Data.define(:success, :record, :error_code, :error_message) do
    def success? = success
    def failure? = !success
  end
end
