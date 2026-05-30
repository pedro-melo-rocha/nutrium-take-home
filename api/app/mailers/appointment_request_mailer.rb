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

  def slot_unavailable
    @request      = params[:request]
    @nutritionist = @request.nutritionist
    @service      = @request.service
    @starts_at    = @request.starts_at

    mail(
      to:      @request.guest_email,
      subject: "Your appointment request couldn't be confirmed (slot no longer available)"
    )
  end
end
