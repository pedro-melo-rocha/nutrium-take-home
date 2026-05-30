require "rails_helper"

RSpec.describe "Appointment notification enqueue", type: :service do
  include ActiveJob::TestHelper

  let(:nutritionist) { create(:nutritionist) }
  let(:service) { create(:service, nutritionist: nutritionist, duration_minutes: 60) }

  def make_request(starts_at:, guest_email: nil)
    create(
      :appointment_request,
      service: service,
      nutritionist: nutritionist,
      guest_email: guest_email || "guest-#{SecureRandom.hex(3)}@example.com",
      starts_at: starts_at
    )
  end

  describe "AppointmentRequests::Accept" do
    it "enqueues an `accepted` mail to the guest on success" do
      req = make_request(starts_at: 2.days.from_now)

      expect {
        AppointmentRequests::Accept.new.call(req)
      }.to have_enqueued_mail(AppointmentRequestMailer, :accepted)
        .with(params: { request: req }, args: [])
    end

    it "enqueues a `slot_unavailable` mail for each auto-rejected overlap" do
      start_a = 2.days.from_now.change(hour: 10)
      target  = make_request(starts_at: start_a)
      overlap_a = make_request(starts_at: start_a + 30.minutes)
      overlap_b = make_request(starts_at: start_a + 15.minutes)

      expect {
        AppointmentRequests::Accept.new.call(target)
      }.to have_enqueued_mail(AppointmentRequestMailer, :slot_unavailable).twice
        .and have_enqueued_mail(AppointmentRequestMailer, :accepted).once

      [ overlap_a, overlap_b ].each { |r| expect(r.reload).to be_rejected }
    end

    it "does NOT enqueue any mail when the accept fails with overlap_conflict" do
      start_a = 2.days.from_now.change(hour: 10)
      first   = make_request(starts_at: start_a)
      AppointmentRequests::Accept.new.call(first)

      second = make_request(starts_at: start_a + 30.minutes)

      expect {
        result = AppointmentRequests::Accept.new.call(second)
        expect(result).to be_failure
        expect(result.error_code).to eq(:overlap_conflict)
      }.not_to have_enqueued_mail(AppointmentRequestMailer)
    end

    it "does NOT enqueue mail when the record is in an invalid state" do
      req = make_request(starts_at: 2.days.from_now)
      req.update!(status: :rejected)

      expect {
        AppointmentRequests::Accept.new.call(req)
      }.not_to have_enqueued_mail(AppointmentRequestMailer)
    end
  end

  describe "AppointmentRequests::Reject" do
    it "enqueues a `rejected` mail to the guest on success" do
      req = make_request(starts_at: 2.days.from_now)

      expect {
        AppointmentRequests::Reject.new.call(req)
      }.to have_enqueued_mail(AppointmentRequestMailer, :rejected)
        .with(params: { request: req }, args: [])
    end

    it "does NOT enqueue when reject fails (e.g., accepted state)" do
      req = make_request(starts_at: 2.days.from_now)
      req.update!(status: :accepted)

      expect {
        AppointmentRequests::Reject.new.call(req)
      }.not_to have_enqueued_mail(AppointmentRequestMailer)
    end
  end

  describe "AppointmentRequests::Create (no submit-confirmation mail by design)" do
    it "does NOT enqueue any mail on successful create" do
      params = {
        service_id: service.id,
        guest_name: "Sara",
        guest_email: "sara@example.com",
        starts_at: 2.days.from_now
      }

      expect {
        AppointmentRequests::Create.new.call(params)
      }.not_to have_enqueued_mail(AppointmentRequestMailer)
    end
  end
end
