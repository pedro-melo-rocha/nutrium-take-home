class ApplicationJob < ActiveJob::Base
  # Auto-retry on transient infrastructure errors. Polynomial backoff means
  # successive retries wait ~3s, ~16s, ~81s, ~256s, ~625s — enough time for
  # short SMTP/network blips without hammering an unhealthy upstream.
  #
  # NOTE: Net::SMTP* errors only matter once we configure real SMTP delivery
  # (currently letter_opener in dev, :test in test). They're declared anyway
  # so the contract is in place for the future real-send swap.
  retry_on Net::OpenTimeout,            wait: :polynomially_longer, attempts: 5
  retry_on Errno::ECONNRESET,           wait: :polynomially_longer, attempts: 5
  retry_on Errno::ECONNREFUSED,         wait: :polynomially_longer, attempts: 5
  retry_on Net::ReadTimeout,            wait: :polynomially_longer, attempts: 5

  # ActiveRecord deadlock = retry-able. The retry cost is small vs the cost
  # of dropping a notification.
  retry_on ActiveRecord::Deadlocked,    wait: :polynomially_longer, attempts: 3

  # If the record was deleted between enqueue and execution, no point retrying.
  # Job is discarded silently (logged at info level by ActiveJob).
  discard_on ActiveJob::DeserializationError
end
