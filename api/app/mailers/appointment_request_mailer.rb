# Guest-facing transactional emails for an appointment request lifecycle.
#
# Usage (always via deliver_later, always AFTER the model transaction commits):
#
#   AppointmentRequestMailer.with(request: req).accepted.deliver_later
#   AppointmentRequestMailer.with(request: req).rejected.deliver_later
#   AppointmentRequestMailer.with(request: req).canceled_by_overlap.deliver_later
#
# Why not the more obvious AppointmentMailer.accepted(req)? The `.with(...)`
# pattern serializes only the GlobalID of `req`, not the whole record. That
# means the job survives serialization to Solid Queue without dragging
# stale attributes; the worker reloads the row when it dequeues.
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

  # Sent to guests whose pending requests were auto-canceled because the
  # nutritionist accepted a different overlapping request. Separate copy
  # from `rejected` so we can be precise: this is not a personal "no",
  # it's a slot conflict.
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
