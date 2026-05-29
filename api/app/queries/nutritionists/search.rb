module Nutritionists
  # Lists nutritionists whose services match the search terms.
  #
  # Inputs: `q` matches Nutritionist#name OR Service#name (case-insensitive);
  # `location` is case-insensitive equality on Service#location.
  #
  # Spec rule: a blank OR "invalid" location falls back to "Braga". "Invalid"
  # collapses into "yields zero results" — no canonical location list needed.
  # `#location` reports the location actually used after any fallback, so the
  # UI can label results ("Showing results for Braga").
  #
  # Name match alone is not enough: a nutritionist with services only in Porto
  # must NOT appear in a Braga search. Embedded services are filtered to the
  # resolved location.
  class Search
    DEFAULT_LOCATION = "Braga".freeze

    attr_reader :q

    def initialize(q: nil, location: nil)
      @q = q.to_s.strip.presence
      @requested_location = location.to_s.strip.presence
    end

    def results
      compute
      @results
    end

    # Location actually used after any fallback. Triggers the search.
    def location
      compute
      @location
    end

    private

    def compute
      return if @computed

      requested = @requested_location || DEFAULT_LOCATION
      found = nutritionists_for(requested)

      # Blank or invalid (zero-hit) location → Braga. Skip the second query when
      # the request was already Braga or already produced hits.
      if found.empty? && requested.casecmp(DEFAULT_LOCATION) != 0
        @location = DEFAULT_LOCATION
        @results = nutritionists_for(DEFAULT_LOCATION)
      else
        @location = requested
        @results = found
      end

      @computed = true
    end

    def nutritionists_for(location)
      services = Service.where("LOWER(location) = LOWER(?)", location)
      services = filter_services_by_query(services) if q.present?

      services_by_nutri = services.to_a.group_by(&:nutritionist_id)
      nutri_ids = services_by_nutri.keys
      return [] if nutri_ids.empty?

      Nutritionist
        .where(id: nutri_ids)
        .order(:name)
        .map { |n| serialize(n, services_by_nutri[n.id]) }
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
