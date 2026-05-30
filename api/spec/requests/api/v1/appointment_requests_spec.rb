require "rails_helper"

RSpec.describe "Api::V1::AppointmentRequests", type: :request do
  let(:nutritionist) { create(:nutritionist) }
  let(:service)      { create(:service, nutritionist: nutritionist, duration_minutes: 60) }

  def post_create(overrides = {})
    payload = {
      appointment_request: {
        service_id: service.id,
        guest_name: "Sara Pinto",
        guest_email: "sara.pinto@example.com",
        starts_at: 2.days.from_now.iso8601
      }.merge(overrides)
    }
    post "/api/v1/appointment_requests", params: payload, as: :json
  end

  describe "POST /api/v1/appointment_requests" do
    it "returns 201 and the new pending request" do
      post_create

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json["status"]).to eq("pending")
      expect(json["guest_email"]).to eq("sara.pinto@example.com")
      expect(json["service"]["id"]).to eq(service.id)
      expect(json["nutritionist"]["id"]).to eq(nutritionist.id)
    end

    it "supersedes prior pendings for the same guest_email" do
      post_create
      first_id = response.parsed_body["id"]

      post_create(starts_at: 3.days.from_now.iso8601)

      expect(response).to have_http_status(:created)
      expect(AppointmentRequest.find(first_id).status).to eq("rejected")
    end

    it "returns 422 on validation failure (past starts_at)" do
      post_create(starts_at: 1.day.ago.iso8601)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["code"]).to eq("validation_failed")
    end

    it "returns 422 on invalid email" do
      post_create(guest_email: "not-an-email")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["code"]).to eq("validation_failed")
    end
  end

  describe "GET /api/v1/appointment_requests/lookup" do
    it "returns 422 when guest_email missing" do
      get "/api/v1/appointment_requests/lookup"

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["code"]).to eq("missing_guest_email")
    end

    it "returns { active: null } when no active request exists" do
      get "/api/v1/appointment_requests/lookup", params: { guest_email: "nobody@example.com" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["active"]).to be_nil
    end

    it "returns the most recent pending request for the email" do
      create(:appointment_request,
        nutritionist: nutritionist,
        service: service,
        guest_email: "sara@example.com",
        starts_at: 2.days.from_now)

      get "/api/v1/appointment_requests/lookup", params: { guest_email: "sara@example.com" }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["active"]).not_to be_nil
      expect(json["active"]["status"]).to eq("pending")
      expect(json["active"]["nutritionist"]["id"]).to eq(nutritionist.id)
    end

    it "returns an accepted request if no pending exists" do
      req = create(:appointment_request,
        nutritionist: nutritionist,
        service: service,
        guest_email: "sara@example.com",
        starts_at: 2.days.from_now)
      req.update!(status: :accepted)

      get "/api/v1/appointment_requests/lookup", params: { guest_email: "sara@example.com" }

      expect(response.parsed_body["active"]["status"]).to eq("accepted")
    end

    it "does NOT return rejected requests as active" do
      create(:appointment_request,
        nutritionist: nutritionist, service: service,
        guest_email: "sara@example.com", starts_at: 3.days.from_now).update!(status: :rejected)

      get "/api/v1/appointment_requests/lookup", params: { guest_email: "sara@example.com" }

      expect(response.parsed_body["active"]).to be_nil
    end

    it "is case-insensitive on email lookup" do
      create(:appointment_request,
        nutritionist: nutritionist, service: service,
        guest_email: "Sara@Example.com", starts_at: 2.days.from_now)

      get "/api/v1/appointment_requests/lookup", params: { guest_email: "SARA@EXAMPLE.COM" }

      expect(response.parsed_body["active"]).not_to be_nil
    end
  end
end
