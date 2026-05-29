module Nutritionists
  # Inputs: `q` matches Nutritionist#name OR Service#name (case-insensitive);
  # `location` is case-insensitive equality on Service#location.
  #
  # Spec rules:
  #   - Blank `location` → default to "Braga".
  #   - Non-blank `location` is honored AS-TYPED (don't silently fall back).
  #   - Empty results + fallback has hits → expose `#suggestion` so the UI
  #     can prompt "No hits in Porto. Show 6 in Braga?" without surprise.
  #   - Name match alone is not enough: a nutritionist with services only in
  #     Porto must NOT appear in a Braga search.
  #   - Embedded services in the response are filtered to the chosen location.
  class Search
    DEFAULT_LOCATION = "Braga".freeze

    attr_reader :q, :location

    # True when the resolved location came from the default fallback rather
    # than user input — used to suppress meaningless self-suggestions.
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

    # Returns `{ location:, results_count: }` when the current search is empty
    # AND the user typed a non-default location that has data elsewhere, else nil.
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

    # Count distinct nutritionists at `fallback_location` matching the SAME
    # `q` — so the suggestion is meaningful for the user's search, not just
    # "Braga has data in general".
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
