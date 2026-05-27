module Nutritionists
  # Search query object for the public nutritionist listing.
  #
  # Inputs:
  #   q        — free-text; matches Nutritionist#name OR Service#name (case-insensitive)
  #   location — service location filter (case-insensitive equality)
  #
  # Spec behavior:
  #   - When `location` is blank, default to "Braga".
  #   - When `location` is non-blank but has zero matches, fall back to "Braga".
  #   - A nutritionist appears if at least one of their services at the chosen
  #     location matches `q` (or any service at that location, if `q` is blank).
  #     Name matches alone are NOT enough: a nutritionist whose only services
  #     are in Porto should not appear in a Braga search.
  #   - Services attached to each returned nutritionist are filtered to the
  #     chosen location.
  #
  # Returns an Array<Hash> ready for JSON rendering. Keeps controller skinny.
  class Search
    DEFAULT_LOCATION = "Braga".freeze

    attr_reader :q, :location

    def initialize(q: nil, location: nil)
      @q = q.to_s.strip.presence
      @location = resolve_location(location)
    end

    def results
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

    private

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

    def resolve_location(input)
      candidate = input.to_s.strip.presence
      return DEFAULT_LOCATION if candidate.nil?

      Service.where("LOWER(location) = LOWER(?)", candidate).exists? ? candidate : DEFAULT_LOCATION
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
