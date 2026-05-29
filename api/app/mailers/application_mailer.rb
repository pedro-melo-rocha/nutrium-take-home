class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "no-reply@nutri-app.local")
  layout "mailer"
end
