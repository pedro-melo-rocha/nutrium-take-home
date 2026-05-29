module Nutritionists
  class Search
    DEFAULT_LOCATION = "Braga".freeze
    DEFAULT_PER_PAGE = 10
    MAX_PER_PAGE = 50

    attr_reader :q, :page, :per_page

    def initialize(q: nil, location: nil, page: nil, per_page: nil)
      @q = q.to_s.strip.presence
      @requested_location = location.to_s.strip.presence
      @page = normalize_page(page)
      @per_page = normalize_per_page(per_page)
    end

    def results
      compute
      @results
    end

    def location
      compute
      @location
    end

    def pagination
      compute
      {
        page: @page,
        per_page: @per_page,
        total_count: @total_count,
        total_pages: (@total_count.to_f / @per_page).ceil
      }
    end

    private

    def compute
      return if @computed

      @location = resolve_location
      scope = matching_nutritionists(@location)
      @total_count = scope.count

      page_records = scope.limit(@per_page).offset((@page - 1) * @per_page).to_a
      @results = serialize_page(page_records, @location)

      @computed = true
    end

    def resolve_location
      requested = @requested_location || DEFAULT_LOCATION
      return requested if requested.casecmp(DEFAULT_LOCATION).zero?
      return requested if matching_nutritionists(requested).exists?

      DEFAULT_LOCATION
    end

    def matching_nutritionists(location)
      Nutritionist
        .where(id: matching_services(location).select(:nutritionist_id))
        .order(:name, :id)
    end

    def matching_services(location)
      scope = Service.where("LOWER(location) = LOWER(?)", location)
      return scope if q.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(q.downcase)}%"
      nutri_ids_by_name = Nutritionist.where("LOWER(name) LIKE ?", pattern).pluck(:id)

      scope.where(
        "LOWER(services.name) LIKE :pattern OR services.nutritionist_id IN (:ids)",
        pattern: pattern,
        ids: nutri_ids_by_name
      )
    end

    def serialize_page(nutritionists, location)
      return [] if nutritionists.empty?

      services_by_nutri = matching_services(location)
        .where(nutritionist_id: nutritionists.map(&:id))
        .to_a
        .group_by(&:nutritionist_id)

      nutritionists.map { |n| serialize(n, services_by_nutri[n.id]) }
    end

    def normalize_page(value)
      n = value.to_i
      n < 1 ? 1 : n
    end

    def normalize_per_page(value)
      n = value.to_i
      return DEFAULT_PER_PAGE if n < 1

      [ n, MAX_PER_PAGE ].min
    end

    def serialize(nutri, services)
      {
        id: nutri.id,
        name: nutri.name,
        title: nutri.title,
        license_number: nutri.license_number,
        photo_url: nutri.photo_url,
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
