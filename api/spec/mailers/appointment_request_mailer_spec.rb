require "rails_helper"

RSpec.describe AppointmentRequestMailer, type: :mailer do
  let(:nutritionist) { create(:nutritionist, name: "Ana Silva") }
  let(:service) do
    create(:service,
      nutritionist: nutritionist,
      name: "Initial Consultation",
      price_cents: 5500,
      duration_minutes: 60,
      location: "Braga")
  end
  let(:request_record) do
    create(:appointment_request,
      nutritionist: nutritionist,
      service: service,
      guest_name: "Pedro",
      guest_email: "pedro@example.com",
      starts_at: Time.zone.local(2026, 7, 15, 10, 0))
  end

  describe "#accepted" do
    let(:mail) { described_class.with(request: request_record).accepted }

    it "addresses the guest" do
      expect(mail.to).to eq(["pedro@example.com"])
    end

    it "uses the configured default From" do
      expect(mail.from).to eq([ENV.fetch("MAIL_FROM", "no-reply@nutri-app.local")])
    end

    it "has a precise subject" do
      expect(mail.subject).to eq("Your appointment request was accepted")
    end

    it "renders the nutritionist's name in the body" do
      expect(mail.body.encoded).to include("Ana Silva")
    end

    it "renders the service name + price + location" do
      body = mail.body.encoded
      expect(body).to include("Initial Consultation")
      expect(body).to include("Braga")
      expect(body).to include("55.00")
    end

    it "is multipart (html + text)" do
      expect(mail.body.parts.map(&:content_type).map { |c| c.split(";").first }).to contain_exactly("text/plain", "text/html")
    end
  end

  describe "#rejected" do
    let(:mail) { described_class.with(request: request_record).rejected }

    it "addresses the guest" do
      expect(mail.to).to eq(["pedro@example.com"])
    end

    it "has a precise subject" do
      expect(mail.subject).to eq("Your appointment request was declined")
    end

    it "renders the nutritionist's name" do
      expect(mail.body.encoded).to include("Ana Silva")
    end

    it "is multipart" do
      expect(mail.body.parts.size).to eq(2)
    end
  end

  describe "#canceled_by_overlap" do
    let(:mail) { described_class.with(request: request_record).canceled_by_overlap }

    it "addresses the guest" do
      expect(mail.to).to eq(["pedro@example.com"])
    end

    it "uses a distinct subject from #rejected (slot conflict, not personal no)" do
      expect(mail.subject).to eq("Your appointment request was canceled (slot no longer available)")
      expect(mail.subject).not_to include("declined")
    end

    it "frames the cancellation as a slot conflict, not a rejection" do
      body = mail.body.encoded
      expect(body).to include("no longer available")
      expect(body).to include("wasn't a rejection")
    end
  end
end
