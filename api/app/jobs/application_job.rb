class ApplicationJob < ActiveJob::Base
  # Polynomial backoff: ~3s, ~16s, ~81s, ~256s, ~625s — rides out short
  # SMTP/network blips without hammering an unhealthy upstream.
  retry_on Net::OpenTimeout,            wait: :polynomially_longer, attempts: 5
  retry_on Errno::ECONNRESET,           wait: :polynomially_longer, attempts: 5
  retry_on Errno::ECONNREFUSED,         wait: :polynomially_longer, attempts: 5
  retry_on Net::ReadTimeout,            wait: :polynomially_longer, attempts: 5

  retry_on ActiveRecord::Deadlocked,    wait: :polynomially_longer, attempts: 3

  # Record was deleted between enqueue and execution — drop the job.
  discard_on ActiveJob::DeserializationError
end
