require "rails_helper"

RSpec.describe AppointmentRequests::Reject do
  let(:nutritionist) { create(:nutritionist) }
  let(:service) { create(:service, nutritionist: nutritionist) }
  let(:req) { create(:appointment_request, service: service, nutritionist: nutritionist) }

  describe "#call" do
    it "marks the request as rejected on happy path" do
      result = described_class.new.call(req)
      expect(result).to be_success
      expect(req.reload).to be_rejected
    end

    it "is idempotent on already-rejected" do
      req.update!(status: :rejected)
      result = described_class.new.call(req)
      expect(result).to be_success
      expect(req.reload).to be_rejected
    end

    it "fails with invalid_state when request is accepted" do
      req.update!(status: :accepted)
      result = described_class.new.call(req)
      expect(result).to be_failure
      expect(result.error_code).to eq(:invalid_state)
    end
  end
end
