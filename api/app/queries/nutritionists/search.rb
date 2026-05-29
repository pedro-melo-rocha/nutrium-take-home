module Nutritionists
  # Search query object for the public nutritionist listing.
  #
  # Inputs:
  #   q        — free-text; matches Nutritionist#name OR Service#name (case-insensitive)
  #   location — service location filter (case-insensitive equality)
  #
  # Spec behavior (P2-FIX, 2026-05-29):
  #   - When `location` is blank, default to "Braga" (spec rule).
  #   - When `location` is non-blank, honor it AS-TYPED — even if it returns
  #     zero results. Previous behavior silently fell back to Braga, which
  #     surprised users searching "Porto" and seeing Braga results.
  #   - When results are empty AND a fallback location has data, expose the
  #     fallback in #suggestion so the UI can render "No hits in Porto.
  #     Show 6 in Braga?" — discoverability without silent surprise.
  #   - Name matches alone are NOT enough: a nutritionist whose only services
  #     are in Porto should not appear in a Braga search.
  #   - Embedded services are filtered to the chosen location.
  #
  # The suggestion strategy is intentionally pluggable. Today: hardcoded
  # `DEFAULT_LOCATION`. Future: swap for geo-IP lookup, distance ranking,
  # or popularity heuristic. Same response shape.
  #
  # Returns array of hashes ready for JSON rendering. Keeps controller skinny.
  class Search
    DEFAULT_LOCATION = "Braga".freeze

    attr_reader :q, :location

    # `location_was_blank` tells callers whether the resolved location came
    # from default fallback (blank input) or from the user's own input.
    # The controller uses this to decide whether suggestion is appropriate
    # (no point suggesting Braga when results are 0 in Braga itself).
    attr_reader :location_was_blank

    def initialize(q: nil, location: nil)
      @q = q.to_s.strip.presence
      candidate = location.to_s.strip.presence
      @location_was_blank = candidate.nil?
      @location = candidate || DEFAULT_LOCATION
    end

    def results
      @results ||= compute_results
    end

    # When the current search returns zero results AND the user typed a
    # non-default location, surface a fallback that DOES have hits.
    # Returns nil if no useful suggestion can be made.
    def suggestion
      return nil if results.any?
      return nil if location_was_blank
      return nil if location.casecmp(DEFAULT_LOCATION).zero?

      count = fallback_count_for(DEFAULT_LOCATION)
      return nil if count.zero?

      { location: DEFAULT_LOCATION, results_count: count }
    end

    private

    def compute_results
      services = base_services_scope
      services = filter_services_by_query(services) if q.present?

      services_by_nutri = services.to_a.group_by(&:nutritionist_id)
      nutri_ids = services_by_nutri.keys
      return [] if nutri_ids.empty?

      Nutritionist
        .where(id: nutri_ids)
        .order(:name)
        .map { |n| serialize(n, services_by_nutri[n.id]) }
    end

    def base_services_scope
      Service.where("LOWER(location) = LOWER(?)", location)
    end

    def filter_services_by_query(scope)
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(q.downcase)}%"
      nutri_ids_by_name = Nutritionist.where("LOWER(name) LIKE ?", pattern).pluck(:id)

      scope.where(
        "LOWER(services.name) LIKE :pattern OR services.nutritionist_id IN (:ids)",
        pattern: pattern,
        ids: nutri_ids_by_name
      )
    end

    # Count of distinct nutritionists at the fallback location that would
    # match the same `q` (so the suggestion is meaningful for the user's
    # search, not just "Braga has data in general").
    def fallback_count_for(fallback_location)
      scope = Service.where("LOWER(location) = LOWER(?)", fallback_location)
      if q.present?
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(q.downcase)}%"
        nutri_ids_by_name = Nutritionist.where("LOWER(name) LIKE ?", pattern).pluck(:id)
        scope = scope.where(
          "LOWER(services.name) LIKE :pattern OR services.nutritionist_id IN (:ids)",
          pattern: pattern,
          ids: nutri_ids_by_name
        )
      end
      scope.distinct.count(:nutritionist_id)
    end

    def serialize(nutri, services)
      {
        id: nutri.id,
        name: nutri.name,
        services: (services || []).map { |s|
          {
            id: s.id,
            name: s.name,
            price_cents: s.price_cents,
            location: s.location,
            duration_minutes: s.duration_minutes
          }
        }
      }
    end
  end
end
