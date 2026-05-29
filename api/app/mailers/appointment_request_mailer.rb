# Always invoke via `.with(request: req).<action>.deliver_later` AFTER the
# model txn commits. `.with(...)` serializes only the record's GlobalID, so
# the worker reloads on dequeue instead of carrying stale attributes.
class AppointmentRequestMailer < ApplicationMailer
  def accepted
    @request      = params[:request]
    @nutritionist = @request.nutritionist
    @service      = @request.service
    @starts_at    = @request.starts_at

    mail(
      to:      @request.guest_email,
      subject: "Your appointment request was accepted"
    )
  end

  def rejected
    @request      = params[:request]
    @nutritionist = @request.nutritionist
    @service      = @request.service
    @starts_at    = @request.starts_at

    mail(
      to:      @request.guest_email,
      subject: "Your appointment request was declined"
    )
  end

  # Slot conflict, not a personal "no" — separate copy from `rejected`.
  def canceled_by_overlap
    @request      = params[:request]
    @nutritionist = @request.nutritionist
    @service      = @request.service
    @starts_at    = @request.starts_at

    mail(
      to:      @request.guest_email,
      subject: "Your appointment request was canceled (slot no longer available)"
    )
  end
end
