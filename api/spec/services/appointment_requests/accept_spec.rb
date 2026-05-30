require "rails_helper"

RSpec.describe AppointmentRequests::Accept do
  let(:nutritionist) { create(:nutritionist) }
  let(:service)      { create(:service, nutritionist: nutritionist, duration_minutes: 60) }

  def make_request(starts_at:, guest_email: nil)
    create(
      :appointment_request,
      service: service,
      nutritionist: nutritionist,
      guest_email: guest_email || "guest-#{SecureRandom.hex(3)}@example.com",
      starts_at: starts_at
    )
  end

  describe "#call" do
    it "marks the request as accepted on happy path" do
      req = make_request(starts_at: 2.days.from_now)

      result = described_class.new.call(req)

      expect(result).to be_success
      expect(req.reload).to be_accepted
    end

    it "is idempotent: accepting an already-accepted request is a no-op" do
      req = make_request(starts_at: 2.days.from_now)
      req.update!(status: :accepted)

      result = described_class.new.call(req)
      expect(result).to be_success
      expect(req.reload).to be_accepted
    end

    it "rejects (invalid_state) accepting an already-rejected request" do
      req = make_request(starts_at: 2.days.from_now)
      req.update!(status: :rejected)

      result = described_class.new.call(req)
      expect(result).to be_failure
      expect(result.error_code).to eq(:invalid_state)
    end

    it "auto-rejects OTHER overlapping pending requests for the same nutritionist" do
      start_a = 2.days.from_now.change(hour: 10) # 10:00..11:00
      target  = make_request(starts_at: start_a)

      overlap_partial = make_request(starts_at: start_a + 30.minutes)
      overlap_inside  = make_request(starts_at: start_a + 15.minutes)
      disjoint        = make_request(starts_at: start_a + 2.hours)

      result = described_class.new.call(target)
      expect(result).to be_success

      expect(target.reload).to be_accepted
      expect(overlap_partial.reload).to be_rejected
      expect(overlap_inside.reload).to be_rejected
      expect(disjoint.reload).to be_pending
    end

    it "treats a touching slot (ends_at == next.starts_at) as NON-overlapping (tstzrange [) semantics)" do
      start_a = 2.days.from_now.change(hour: 10)
      target  = make_request(starts_at: start_a)         
      touching = make_request(starts_at: target.ends_at)

      result = described_class.new.call(target)
      expect(result).to be_success

      expect(touching.reload).to be_pending
    end

    it "does NOT reject overlapping pending requests for a DIFFERENT nutritionist" do
      other_nutri   = create(:nutritionist)
      other_service = create(:service, nutritionist: other_nutri, duration_minutes: 60)
      start_a = 2.days.from_now.change(hour: 10)

      target = make_request(starts_at: start_a)
      other_overlap = create(
        :appointment_request,
        service: other_service,
        nutritionist: other_nutri,
        guest_email: "x@example.com",
        starts_at: start_a + 30.minutes
      )

      described_class.new.call(target)
      expect(other_overlap.reload).to be_pending
    end

    it "returns overlap_conflict when an accepted request already covers the same slot" do
      start_a = 2.days.from_now.change(hour: 10)
      first  = make_request(starts_at: start_a)

      expect(described_class.new.call(first)).to be_success
      first.reload

      second = make_request(starts_at: start_a + 30.minutes) # overlaps first

      result = described_class.new.call(second)
      expect(result).to be_failure
      expect(result.error_code).to eq(:overlap_conflict)
      expect(second.reload).to be_pending # GiST exclusion rolled back the UPDATE
    end
  end
end
