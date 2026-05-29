require "rails_helper"

RSpec.describe AppointmentRequests::Create do
  let(:nutritionist) { create(:nutritionist) }
  let(:service) { create(:service, nutritionist: nutritionist) }
  let(:base_params) do
    {
      service_id: service.id,
      guest_name: "Sara Pinto",
      guest_email: "sara.pinto@example.com",
      starts_at: 2.days.from_now
    }
  end

  describe "#call" do
    it "creates a pending request on happy path" do
      result = described_class.new.call(base_params)

      expect(result).to be_success
      expect(result.record).to be_persisted
      expect(result.record).to be_pending
    end

    it "snapshots ends_at from service duration" do
      result = described_class.new.call(base_params)
      expect(result.record.ends_at).to be_within(1.second).of(result.record.starts_at + service.duration_minutes.minutes)
    end

    it "supersedes prior pending requests from the same guest_email (case-insensitive)" do
      first = described_class.new.call(base_params).record

      second_result = described_class.new.call(base_params.merge(
        guest_email: "SARA.pinto@example.com",      # case-mismatched
        starts_at: 3.days.from_now
      ))

      expect(second_result).to be_success
      expect(first.reload).to be_canceled
      expect(AppointmentRequest.pending.where(guest_email: "sara.pinto@example.com").count).to eq(1)
    end

    it "does NOT touch accepted requests from the same guest" do
      first = described_class.new.call(base_params).record
      first.update!(status: :accepted)

      described_class.new.call(base_params.merge(starts_at: 5.days.from_now))

      expect(first.reload).to be_accepted
    end

    it "returns validation_failed when starts_at is in the past" do
      result = described_class.new.call(base_params.merge(starts_at: 1.day.ago))

      expect(result).to be_failure
      expect(result.error_code).to eq(:validation_failed)
    end

    it "returns validation_failed when guest_email is malformed" do
      result = described_class.new.call(base_params.merge(guest_email: "not-an-email"))

      expect(result).to be_failure
      expect(result.error_code).to eq(:validation_failed)
    end

    it "returns validation_failed when explicit nutritionist_id mismatches service.nutritionist_id" do
      # The Create service auto-syncs nutritionist_id from the service when
      # it's not supplied (see the model callback). So we have to pass an
      # explicit mismatched nutritionist_id to exercise this validator.
      mismatch_nutri = create(:nutritionist)
      result = described_class.new.call(base_params.merge(nutritionist_id: mismatch_nutri.id))

      expect(result).to be_failure
      expect(result.error_code).to eq(:validation_failed)
      expect(result.error_message).to include("must belong to the chosen nutritionist")
    end
  end
end
