require "net/http"

# Finds food, cafés, bars and karaoke near a point using OpenStreetMap's Overpass API.
class NearbyPlaces
  ENDPOINT = URI("https://overpass-api.de/api/interpreter")
  USER_AGENT = "midstop/1.0 (https://github.com/jaemgri/midstop)"
  RADIUS_METERS = 450
  METERS_PER_MINUTE = 80 # the standard walking pace in Japanese property listings
  PER_CATEGORY = 5
  CATEGORY_ORDER = ["Food", "Cafés", "Drinks", "Karaoke"].freeze

  Place = Data.define(:name, :name_en, :category, :walk_minutes)

  def initialize(lat:, lon:, cache_key:)
    @lat = lat
    @lon = lon
    @cache_key = cache_key
  end

  # Returns { "Food" => [Place, ...], ... }, or nil if Overpass couldn't be reached.
  def call
    raw = Rails.cache.fetch(@cache_key, expires_in: 1.week, skip_nil: true) { fetch }
    return nil if raw.nil?

    raw.map { |item| build_place(item) }
       .sort_by(&:walk_minutes)
       .group_by(&:category)
       .transform_values { |places| places.first(PER_CATEGORY) }
       .sort_by { |category, _| CATEGORY_ORDER.index(category) || 99 }
       .to_h
  end

  private

  def fetch
    query = <<~QL
      [out:json][timeout:20];
      nwr["name"]["amenity"~"^(cafe|restaurant|fast_food|bar|pub|karaoke_box)$"](around:#{RADIUS_METERS},#{@lat},#{@lon});
      out center 300;
    QL

    http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 25

    request = Net::HTTP::Post.new(ENDPOINT)
    request["User-Agent"] = USER_AGENT
    request.set_form_data(data: query)

    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch("elements", []).filter_map { |element| parse(element) }
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, JSON::ParserError => e
    Rails.logger.warn("NearbyPlaces failed: #{e.class}: #{e.message}")
    nil
  end

  def parse(element)
    tags = element["tags"] || {}
    lat = element["lat"] || element.dig("center", "lat")
    lon = element["lon"] || element.dig("center", "lon")
    return nil if tags["name"].blank? || lat.nil? || lon.nil?

    { "name" => tags["name"], "name_en" => tags["name:en"], "category" => category_for(tags), "lat" => lat, "lon" => lon }
  end

  def category_for(tags)
    case tags["amenity"]
    when "cafe" then "Cafés"
    when "karaoke_box" then "Karaoke"
    when "bar", "pub" then "Drinks"
    else tags["cuisine"].to_s.include?("izakaya") ? "Drinks" : "Food"
    end
  end

  def build_place(item)
    meters = Geo.distance_km(@lat, @lon, item["lat"], item["lon"]) * 1000
    Place.new(
      name: item["name"],
      name_en: item["name_en"],
      category: item["category"],
      walk_minutes: [(meters / METERS_PER_MINUTE).ceil, 1].max
    )
  end
end
