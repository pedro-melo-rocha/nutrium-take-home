require "rails_helper"

RSpec.describe Nutritionists::Search do
  # Build a small, deterministic fixture set:
  #   - Ana (Braga) offers "Initial Consultation" in Braga and "Online Follow-up" online
  #   - Bruno (Porto) offers "Sports Nutrition" in Porto
  #   - Catarina (Braga) offers "Weight Management" in Braga
  #   - Diogo (Lisboa) offers "Diabetes Counseling" in Lisboa
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

    it "honors a non-blank location AS-TYPED even when it has no services (P2-FIX)" do
      # Old behavior silently fell back to Braga. New behavior respects user
      # intent and surfaces a suggestion instead.
      expect(described_class.new(location: "Atlantis").location).to eq("Atlantis")
    end

    it "preserves casing on the resolved location" do
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

    it "returns empty when no nutritionist at the location matches q" do
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

  describe "#suggestion (P2-FIX)" do
    it "is nil when results are present" do
      search = described_class.new(location: "Braga")
      expect(search.results).not_to be_empty
      expect(search.suggestion).to be_nil
    end

    it "is nil when input was blank (default Braga already applied)" do
      # No point suggesting Braga when the user got Braga by default.
      search = described_class.new(location: nil)
      expect(search.suggestion).to be_nil
    end

    it "is nil when input WAS Braga (the default location) — even when empty" do
      search = described_class.new(q: "kettlebell", location: "Braga")
      expect(search.results).to be_empty
      expect(search.suggestion).to be_nil
    end

    it "returns {location, results_count} when a non-Braga location yields no hits but Braga has matching data" do
      search = described_class.new(location: "Atlantis")
      expect(search.results).to be_empty
      expect(search.suggestion).to eq(location: "Braga", results_count: 2)
    end

    it "respects q when computing fallback count" do
      # Searching `silva` in Atlantis: empty. Suggestion should count only
      # Braga results that ALSO match q — Ana Silva matches, Catarina Lopes
      # does not.
      search = described_class.new(q: "silva", location: "Atlantis")
      expect(search.results).to be_empty
      expect(search.suggestion).to eq(location: "Braga", results_count: 1)
    end

    it "is nil when Braga itself has zero matches for the query" do
      search = described_class.new(q: "kettlebell", location: "Atlantis")
      expect(search.results).to be_empty
      expect(search.suggestion).to be_nil
    end
  end

  describe "JSON shape" do
    it "exposes id, name, price_cents, location, duration_minutes per service" do
      results = described_class.new(location: "Braga").results
      ana_result = results.find { |r| r[:name] == "Ana Silva" }

      expect(ana_result).to include(:id, :name, :services)
      service = ana_result[:services].first
      expect(service).to include(
        :id, :name, :price_cents, :location, :duration_minutes
      )
      expect(service[:name]).to eq("Initial Consultation")
      expect(service[:location]).to eq("Braga")
    end
  end
end
