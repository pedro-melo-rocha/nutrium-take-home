class NutritionistSearch
  DEFAULT_LOCATION = "Braga".freeze
  DEFAULT_PER_PAGE = 10
  MAX_PER_PAGE = 50
  EARTH_RADIUS_KM = 6371.0

  attr_reader :q, :page, :per_page

  def initialize(q: nil, location: nil, page: nil, per_page: nil, lat: nil, lng: nil)
    @q = q.to_s.strip.presence
    @requested_location = location.to_s.strip.presence
    @page = normalize_page(page)
    @per_page = normalize_per_page(per_page)
    @lat = parse_coordinate(lat, 90.0)
    @lng = parse_coordinate(lng, 180.0)
  end

  def results
    compute
    @results
  end

  def location
    compute
    @location
  end

  def geo?
    !@lat.nil? && !@lng.nil?
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

    if geo?
      @location = nil
      @total_count = geo_nutritionist_ids.count
      page_records = geo_relation.limit(@per_page).offset(offset).to_a
      @results = page_records.map { |n| serialize(n, geo_services_for(n), distance_km: n.distance_km) }
    else
      @location = resolve_location
      relation = matching_nutritionists(@location)
      @total_count = relation.count
      page_records = relation.limit(@per_page).offset(offset).to_a
      @results = serialize_page(page_records, @location)
    end

    @computed = true
  end

  def offset
    (@page - 1) * @per_page
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
    apply_query(Service.where("LOWER(location) = LOWER(?)", location))
  end

  def serialize_page(nutritionists, location)
    return [] if nutritionists.empty?

    services_by_nutri = matching_services(location)
      .where(nutritionist_id: nutritionists.map(&:id))
      .to_a
      .group_by(&:nutritionist_id)

    nutritionists.map { |n| serialize(n, services_by_nutri[n.id]) }
  end

  def geo_services
    apply_query(Service.where.not(latitude: nil, longitude: nil))
  end

  def geo_nutritionist_ids
    Nutritionist.where(id: geo_services.select(:nutritionist_id))
  end

  def geo_relation
    Nutritionist
      .joins(:services)
      .merge(geo_services)
      .select("nutritionists.*, MIN(#{distance_sql}) AS distance_km")
      .group("nutritionists.id")
      .order(Arel.sql("MIN(#{distance_sql}) ASC"), :name, :id)
  end

  def geo_services_for(nutritionist)
    geo_services.where(nutritionist_id: nutritionist.id).to_a
  end

  def distance_sql
    @distance_sql ||= ActiveRecord::Base.sanitize_sql_array([
      "#{EARTH_RADIUS_KM} * acos(LEAST(1.0, " \
      "cos(radians(?)) * cos(radians(services.latitude)) * " \
      "cos(radians(services.longitude) - radians(?)) + " \
      "sin(radians(?)) * sin(radians(services.latitude))))",
      @lat, @lng, @lat
    ])
  end

  def apply_query(scope)
    return scope if q.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(q.downcase)}%"
    nutri_ids_by_name = Nutritionist.where("LOWER(name) LIKE ?", pattern).pluck(:id)

    scope.where(
      "LOWER(services.name) LIKE :pattern OR services.nutritionist_id IN (:ids)",
      pattern: pattern,
      ids: nutri_ids_by_name
    )
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

  def parse_coordinate(value, limit)
    return nil if value.nil? || value.to_s.strip.empty?

    f = Float(value, exception: false)
    return nil if f.nil? || f < -limit || f > limit

    f
  end

  def serialize(nutri, services, distance_km: nil)
    card = {
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
    card[:distance_km] = distance_km.to_f.round(1) unless distance_km.nil?
    card
  end
end
