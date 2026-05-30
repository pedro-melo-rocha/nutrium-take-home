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

  it "falls back to Braga when an invalid location is given" do
    get "/api/v1/nutritionists", params: { location: "Atlantis" }

    json = response.parsed_body
    expect(json["location"]).to eq("Braga")
    expect(json["results"].map { |r| r["name"] }).to contain_exactly("Ana Silva")
  end

  it "does not include a suggestion key" do
    get "/api/v1/nutritionists", params: { location: "Porto" }

    json = response.parsed_body
    expect(json).not_to have_key("suggestion")
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

  it "includes nutritionist profile fields on each card" do
    ana.update!(title: "Sports Nutritionist", license_number: "PT-0007", photo_url: "https://cdn.example/ana.png")

    get "/api/v1/nutritionists", params: { location: "Braga" }

    card = response.parsed_body["results"].first
    expect(card).to include(
      "title" => "Sports Nutritionist",
      "license_number" => "PT-0007",
      "photo_url" => "https://cdn.example/ana.png"
    )
  end

  it "embeds services scoped to the chosen location" do
    create(:service, nutritionist: ana, name: "Online Follow-up", location: "Online")

    get "/api/v1/nutritionists", params: { location: "Braga" }

    json = response.parsed_body
    ana_result = json["results"].first
    expect(ana_result["services"].map { |s| s["name"] }).to eq([ "Initial Consultation" ])
  end

  it "sorts by distance and reports sorted_by=distance when lat/lng given" do
    near = create(:nutritionist, name: "Near Porto")
    create(:service, nutritionist: near, location: "Porto", latitude: 41.1579, longitude: -8.6291)
    far = create(:nutritionist, name: "Far Lisboa")
    create(:service, nutritionist: far, location: "Lisboa", latitude: 38.7223, longitude: -9.1393)

    get "/api/v1/nutritionists", params: { lat: 41.1579, lng: -8.6291 }

    json = response.parsed_body
    expect(json["sorted_by"]).to eq("distance")
    expect(json["location"]).to be_nil
    names = json["results"].map { |r| r["name"] }
    # Porto-based nutritionist before the Lisboa one; Ana/Bruno (no coords) excluded.
    expect(names).to eq([ "Near Porto", "Far Lisboa" ])
    expect(json["results"].first["distance_km"]).to be_within(0.5).of(0.0)
  end

  it "reports sorted_by=name in location mode" do
    get "/api/v1/nutritionists", params: { location: "Braga" }
    expect(response.parsed_body["sorted_by"]).to eq("name")
  end

  it "returns a pagination block with sensible defaults" do
    get "/api/v1/nutritionists", params: { location: "Braga" }

    expect(response.parsed_body["pagination"]).to eq(
      "page" => 1, "per_page" => 10, "total_count" => 1, "total_pages" => 1
    )
  end

  it "honors page and per_page params" do
    3.times do |i|
      n = create(:nutritionist, name: "Extra #{i}")
      create(:service, nutritionist: n, location: "Braga")
    end

    get "/api/v1/nutritionists", params: { location: "Braga", per_page: 2, page: 2 }

    json = response.parsed_body
    expect(json["results"].size).to eq(2)
    expect(json["pagination"]).to eq(
      "page" => 2, "per_page" => 2, "total_count" => 4, "total_pages" => 2
    )
  end
end
