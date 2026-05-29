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

    it "rejects (invalid_state) accepting a canceled request" do
      req = make_request(starts_at: 2.days.from_now)
      req.update!(status: :canceled)

      result = described_class.new.call(req)
      expect(result).to be_failure
      expect(result.error_code).to eq(:invalid_state)
    end

    it "auto-cancels OTHER overlapping pending requests for the same nutritionist" do
      start_a = 2.days.from_now.change(hour: 10) # 10:00..11:00
      target  = make_request(starts_at: start_a)

      overlap_partial = make_request(starts_at: start_a + 30.minutes) # 10:30..11:30
      overlap_inside  = make_request(starts_at: start_a + 15.minutes) # 10:15..11:15
      disjoint        = make_request(starts_at: start_a + 2.hours)    # 12:00..13:00 (no overlap)

      result = described_class.new.call(target)
      expect(result).to be_success

      expect(target.reload).to be_accepted
      expect(overlap_partial.reload).to be_canceled
      expect(overlap_inside.reload).to be_canceled
      expect(disjoint.reload).to be_pending
    end

    it "treats a touching slot (ends_at == next.starts_at) as NON-overlapping (tstzrange [) semantics)" do
      start_a = 2.days.from_now.change(hour: 10)
      target  = make_request(starts_at: start_a)                  # 10:00..11:00
      touching = make_request(starts_at: target.ends_at)          # 11:00..12:00 — touches, does not overlap

      result = described_class.new.call(target)
      expect(result).to be_success

      expect(touching.reload).to be_pending
    end

    it "does NOT cancel overlapping pending requests for a DIFFERENT nutritionist" do
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
      # second must be CREATED AFTER first is accepted; otherwise first.accept
      # would have already auto-canceled second via the overlap rule, and we
      # would be testing a different code path.
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
