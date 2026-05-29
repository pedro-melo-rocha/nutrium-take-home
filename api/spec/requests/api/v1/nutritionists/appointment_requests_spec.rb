require "rails_helper"

RSpec.describe "GET /api/v1/nutritionists/:id/appointment_requests", type: :request do
  let(:nutritionist) { create(:nutritionist, name: "Ana") }
  let(:other_nutri)  { create(:nutritionist, name: "Bruno") }
  let(:service)      { create(:service, nutritionist: nutritionist) }
  let(:other_svc)    { create(:service, nutritionist: other_nutri) }

  let!(:pending_a)   { create(:appointment_request, nutritionist: nutritionist, service: service, starts_at: 2.days.from_now) }
  let!(:accepted_a)  { create(:appointment_request, nutritionist: nutritionist, service: service, starts_at: 3.days.from_now).tap { |r| r.update!(status: :accepted) } }
  let!(:pending_b)   { create(:appointment_request, nutritionist: other_nutri, service: other_svc, starts_at: 2.days.from_now) }

  it "defaults to status=pending and scopes to the given nutritionist" do
    get "/api/v1/nutritionists/#{nutritionist.id}/appointment_requests"

    expect(response).to have_http_status(:ok)
    json = response.parsed_body
    expect(json["nutritionist"]["id"]).to eq(nutritionist.id)
    ids = json["results"].map { |r| r["id"] }
    expect(ids).to contain_exactly(pending_a.id)
  end

  it "filters by explicit status" do
    get "/api/v1/nutritionists/#{nutritionist.id}/appointment_requests", params: { status: "accepted" }

    ids = response.parsed_body["results"].map { |r| r["id"] }
    expect(ids).to contain_exactly(accepted_a.id)
  end

  it "returns 422 on invalid status" do
    get "/api/v1/nutritionists/#{nutritionist.id}/appointment_requests", params: { status: "garbage" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]["code"]).to eq("invalid_status")
  end

  it "orders by starts_at ascending" do
    create(:appointment_request, nutritionist: nutritionist, service: service, starts_at: 1.day.from_now)
    get "/api/v1/nutritionists/#{nutritionist.id}/appointment_requests"
    starts = response.parsed_body["results"].map { |r| r["starts_at"] }
    expect(starts).to eq(starts.sort)
  end
end
