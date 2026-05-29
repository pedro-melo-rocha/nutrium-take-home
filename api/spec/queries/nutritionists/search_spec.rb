require "rails_helper"

RSpec.describe Nutritionists::Search do
  let!(:ana)       { create(:nutritionist, name: "Ana Silva") }
  let!(:bruno)     { create(:nutritionist, name: "Bruno Costa") }
  let!(:catarina)  { create(:nutritionist, name: "Catarina Lopes") }
  let!(:diogo)     { create(:nutritionist, name: "Diogo Rocha") }

  let!(:ana_braga)    { create(:service, nutritionist: ana, name: "Initial Consultation", location: "Braga") }
  let!(:ana_online)   { create(:service, nutritionist: ana, name: "Online Follow-up", location: "Online") }
  let!(:bruno_porto)  { create(:service, nutritionist: bruno, name: "Sports Nutrition", location: "Porto") }
  let!(:cat_braga)    { create(:service, nutritionist: catarina, name: "Weight Management", location: "Braga") }
  let!(:diogo_lisboa) { create(:service, nutritionist: diogo, name: "Diabetes Counseling", location: "Lisboa") }

  describe "location resolution" do
    it "defaults to Braga when location is blank" do
      expect(described_class.new(location: nil).location).to eq("Braga")
      expect(described_class.new(location: "").location).to eq("Braga")
      expect(described_class.new(location: "   ").location).to eq("Braga")
    end

    it "falls back to Braga when the location is invalid (yields zero results)" do
      expect(described_class.new(location: "Atlantis").location).to eq("Braga")
    end

    it "preserves casing on a location that has hits" do
      expect(described_class.new(location: "porto").location).to eq("porto")
    end

    it "keeps a valid non-default location" do
      expect(described_class.new(location: "Porto").location).to eq("Porto")
    end
  end

  describe "#results" do
    it "returns nutritionists whose services match the resolved location" do
      results = described_class.new(location: "Braga").results

      expect(results.map { |r| r[:name] }).to contain_exactly("Ana Silva", "Catarina Lopes")
    end

    it "filters embedded services to the chosen location only" do
      results = described_class.new(location: "Braga").results
      ana_result = results.find { |r| r[:name] == "Ana Silva" }

      service_names = ana_result[:services].map { |s| s[:name] }
      expect(service_names).to eq([ "Initial Consultation" ])
    end

    it "applies the Braga default when location is blank" do
      results = described_class.new(location: nil).results

      expect(results.map { |r| r[:name] }).to contain_exactly("Ana Silva", "Catarina Lopes")
    end

    it "matches by nutritionist name (q) within the chosen location" do
      # Use "silva" — won't collide with any service name in the fixture set.
      results = described_class.new(q: "silva", location: "Braga").results

      expect(results.map { |r| r[:name] }).to contain_exactly("Ana Silva")
    end

    it "matches by service name (q) within the chosen location" do
      results = described_class.new(q: "weight", location: "Braga").results

      expect(results.map { |r| r[:name] }).to contain_exactly("Catarina Lopes")
    end

    it "is case-insensitive on q" do
      results = described_class.new(q: "WEIGHT", location: "Braga").results
      expect(results.map { |r| r[:name] }).to contain_exactly("Catarina Lopes")
    end

    it "returns empty when no nutritionist at the (default) location matches q" do
      results = described_class.new(q: "kettlebell", location: "Braga").results
      expect(results).to be_empty
    end

    it "does NOT cross-leak nutritionists from other locations" do
      # Bruno's name matches "bruno" but he's only in Porto. Searching Braga
      # for "bruno" must return nothing — name-match alone is not enough.
      results = described_class.new(q: "bruno", location: "Braga").results
      expect(results).to be_empty
    end

    it "returns ordered by nutritionist name" do
      results = described_class.new(location: "Braga").results
      expect(results.map { |r| r[:name] }).to eq([ "Ana Silva", "Catarina Lopes" ])
    end

    it "returns the resolved location and query in the search object" do
      search = described_class.new(q: "silva", location: nil)
      expect(search.location).to eq("Braga")
      expect(search.q).to eq("silva")
    end
  end

  describe "invalid-location fallback to Braga" do
    it "returns Braga results when the typed location has no services" do
      search = described_class.new(location: "Atlantis")

      expect(search.location).to eq("Braga")
      expect(search.results.map { |r| r[:name] }).to contain_exactly("Ana Silva", "Catarina Lopes")
    end

    it "applies q against Braga when falling back" do
      # "weight" matches only Catarina, who is in Braga.
      search = described_class.new(q: "weight", location: "Atlantis")

      expect(search.location).to eq("Braga")
      expect(search.results.map { |r| r[:name] }).to contain_exactly("Catarina Lopes")
    end

    it "returns empty (still resolved to Braga) when Braga also has no match for q" do
      search = described_class.new(q: "kettlebell", location: "Atlantis")

      expect(search.location).to eq("Braga")
      expect(search.results).to be_empty
    end

    it "does not fall back when the requested location has hits" do
      search = described_class.new(location: "Porto")

      expect(search.location).to eq("Porto")
      expect(search.results.map { |r| r[:name] }).to contain_exactly("Bruno Costa")
    end
  end

  describe "pagination" do
    let!(:paged) do
      %w[P1 P2 P3 P4 P5].map do |label|
        n = create(:nutritionist, name: "Paged #{label}")
        create(:service, nutritionist: n, name: "Initial Consultation", location: "Braga")
        n
      end
    end

    it "defaults to page 1 / per_page 10" do
      search = described_class.new(location: "Braga")

      expect(search.page).to eq(1)
      expect(search.per_page).to eq(10)
      expect(search.pagination).to eq(page: 1, per_page: 10, total_count: 7, total_pages: 1)
      expect(search.results.size).to eq(7)
    end

    it "slices results to per_page and reports total meta" do
      search = described_class.new(location: "Braga", per_page: 2, page: 1)

      expect(search.results.size).to eq(2)
      expect(search.pagination).to eq(page: 1, per_page: 2, total_count: 7, total_pages: 4)
    end

    it "returns the next slice on page 2, ordered by name across pages" do
      page1 = described_class.new(location: "Braga", per_page: 2, page: 1).results.map { |r| r[:name] }
      page2 = described_class.new(location: "Braga", per_page: 2, page: 2).results.map { |r| r[:name] }

      all_names = %w[Ana\ Silva Catarina\ Lopes Paged\ P1 Paged\ P2 Paged\ P3 Paged\ P4 Paged\ P5]
      expect(page1).to eq(all_names[0, 2])
      expect(page2).to eq(all_names[2, 2])
      expect(page1 & page2).to be_empty
    end

    it "caps per_page at MAX_PER_PAGE" do
      search = described_class.new(location: "Braga", per_page: 1000)
      expect(search.per_page).to eq(described_class::MAX_PER_PAGE)
    end

    it "coerces blank/invalid page to 1 and blank/invalid per_page to the default" do
      expect(described_class.new(location: "Braga", page: "0", per_page: "-3").page).to eq(1)
      expect(described_class.new(location: "Braga", page: "abc", per_page: "xyz").per_page).to eq(10)
      expect(described_class.new(location: "Braga", page: nil, per_page: nil).page).to eq(1)
    end
  end

  describe "JSON shape" do
    it "exposes profile fields (title, license_number, photo_url) per nutritionist" do
      ana.update!(title: "Clinical Nutritionist", license_number: "PT-0042", photo_url: "https://cdn.example/ana.png")

      results = described_class.new(location: "Braga").results
      ana_result = results.find { |r| r[:name] == "Ana Silva" }

      expect(ana_result).to include(:id, :name, :title, :license_number, :photo_url, :services)
      expect(ana_result[:title]).to eq("Clinical Nutritionist")
      expect(ana_result[:license_number]).to eq("PT-0042")
      expect(ana_result[:photo_url]).to eq("https://cdn.example/ana.png")
    end

    it "exposes id, name, price_cents, location, duration_minutes per service" do
      results = described_class.new(location: "Braga").results
      ana_result = results.find { |r| r[:name] == "Ana Silva" }

      service = ana_result[:services].first
      expect(service).to include(
        :id, :name, :price_cents, :location, :duration_minutes
      )
      expect(service[:name]).to eq("Initial Consultation")
      expect(service[:location]).to eq("Braga")
    end
  end
end
