require "rails_helper"

RSpec.describe "GET /api/v1/nutritionists", type: :request do
  let!(:ana)      { create(:nutritionist, name: "Ana Silva") }
  let!(:bruno)    { create(:nutritionist, name: "Bruno Costa") }
  let!(:ana_braga)   { create(:service, nutritionist: ana, name: "Initial Consultation", location: "Braga") }
  let!(:bruno_porto) { create(:service, nutritionist: bruno, name: "Sports Nutrition", location: "Porto") }

  it "returns 200 with JSON content type" do
    get "/api/v1/nutritionists"

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to start_with("application/json")
  end

  it "defaults to Braga when no location given" do
    get "/api/v1/nutritionists"

    json = response.parsed_body
    expect(json["location"]).to eq("Braga")
    expect(json["results"].map { |r| r["name"] }).to contain_exactly("Ana Silva")
  end

  it "filters by location" do
    get "/api/v1/nutritionists", params: { location: "Porto" }

    json = response.parsed_body
    expect(json["location"]).to eq("Porto")
    expect(json["results"].map { |r| r["name"] }).to contain_exactly("Bruno Costa")
  end

  it "falls back to Braga on unknown location" do
    get "/api/v1/nutritionists", params: { location: "Atlantis" }

    json = response.parsed_body
    expect(json["location"]).to eq("Braga")
    expect(json["results"].map { |r| r["name"] }).to contain_exactly("Ana Silva")
  end

  it "applies q within the resolved location" do
    get "/api/v1/nutritionists", params: { q: "initial", location: "Braga" }

    json = response.parsed_body
    expect(json["query"]).to eq("initial")
    expect(json["results"].map { |r| r["name"] }).to contain_exactly("Ana Silva")
  end

  it "returns empty results array, not error, when nothing matches" do
    get "/api/v1/nutritionists", params: { q: "kettlebell", location: "Braga" }

    json = response.parsed_body
    expect(json["results"]).to eq([])
  end

  it "embeds services scoped to the chosen location" do
    create(:service, nutritionist: ana, name: "Online Follow-up", location: "Online")

    get "/api/v1/nutritionists", params: { location: "Braga" }

    json = response.parsed_body
    ana_result = json["results"].first
    expect(ana_result["services"].map { |s| s["name"] }).to eq(["Initial Consultation"])
  end
end
