module AppointmentRequests
  # Lightweight result object returned by Create/Accept/Reject.
  #
  # Why not return the model or raise?
  #   - Controllers need to distinguish "validation failed" (422) from
  #     "race lost on overlap" (409) from "all good" (200/201) without
  #     a forest of rescue clauses.
  #   - Service objects own the transaction; after_commit-style hooks
  #     (mailers in P4) belong outside the txn.
  Result = Data.define(:success, :record, :error_code, :error_message) do
    def success? = success
    def failure? = !success
  end
end
