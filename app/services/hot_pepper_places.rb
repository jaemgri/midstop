require "net/http"

# Restaurants near a station from the Hot Pepper Gourmet API (by Recruit).
# Returns the same shape as NearbyPlaces: { "heading_id" => [Place, ...] }, or nil on failure.
class HotPepperPlaces
  BASE_URL = "https://webservice.recruit.co.jp/hotpepper"
  RANGE = 2 # 500 m around the station
  COUNT = 100 # the most Hot Pepper returns per request
  PER_CATEGORY = 5
  MAX_FILTERED = 15
  METERS_PER_MINUTE = 80
  CATEGORY_ORDER = %w[food cafes drinks karaoke].freeze

  # Our chips, matched against Hot Pepper's own genre names (so we never hard-code their codes)
  GENRE_PATTERNS = {
    "izakaya" => /居酒屋/,
    "bars" => /バー|バル/,
    "ramen" => /ラーメン/,
    "cafes" => /カフェ/,
    "karaoke" => /カラオケ/
  }.freeze

  def self.available?
    api_key.present?
  end

  def self.api_key
    ENV["HOTPEPPER_API_KEY"]
  end

  # Hot Pepper's genre list: [{ "code" => "G001", "name" => "居酒屋" }, ...]
  def self.genres
    Rails.cache.fetch("hotpepper/genres", expires_in: 1.week, skip_nil: true) do
      request("genre")&.fetch("genre", nil)
    end
  end

  # One API call. Returns the "results" hash, or nil if anything went wrong.
  def self.request(path, params = {})
    uri = URI("#{BASE_URL}/#{path}/v1/")
    uri.query = URI.encode_www_form(params.merge(key: api_key, format: "json"))

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 10

    response = http.get(uri.request_uri)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("HotPepper: #{path} answered HTTP #{response.code}")
      return nil
    end

    results = JSON.parse(response.body)["results"]
    if results.nil? || results["error"]
      Rails.logger.warn("HotPepper: #{path} error #{results&.dig('error').inspect}")
      return nil
    end

    results
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, JSON::ParserError => e
    Rails.logger.warn("HotPepper: #{path} failed: #{e.class}: #{e.message}")
    nil
  end

  def initialize(group_code:, lat:, lon:)
    @group_code = group_code
    @lat = lat
    @lon = lon
  end

  def call(filter: nil, query: nil, preferred: [], max_walk: nil, max_budget: nil)
    keyword = query.to_s.strip
    genre_codes = []

    if filter
      genre_codes = codes_for(filter)
      return nil if genre_codes.nil? # couldn't load the genre list
      return {} if genre_codes.empty?
    end

    shops = search(genre_codes: genre_codes, keyword: keyword)
    return nil if shops.nil?
    shops = shops.select { |shop| within_budget?(shop["budget"], max_budget) } if max_budget

    places = shops.map { |shop| build_place(shop) }.sort_by(&:walk_minutes)
    places = places.select { |place| place.walk_minutes <= max_walk } if max_walk

    if filter || keyword.present?
      heading = filter || "results"
      return places.empty? ? {} : { heading => places.first(MAX_FILTERED) }
    end

    grouped = places.group_by(&:category)
                    .transform_values { |list| list.first(PER_CATEGORY) }
                    .sort_by { |category, _| CATEGORY_ORDER.index(category) || 99 }
                    .to_h

    picks = places.select { |place| preferred.any? { |vibe| GENRE_PATTERNS[vibe]&.match?(place.genre.to_s) } }.first(8)
    picks.any? ? { "for_you" => picks }.merge(grouped) : grouped
  end

  private

  # "2001～3000円" → top of band is 3000. Shops with no listed budget are kept.
  def within_budget?(band, max_budget)
    numbers = band.to_s.scan(/\d+/).map(&:to_i)
    numbers.empty? || numbers.last <= max_budget
  end

  def codes_for(filter)
    pattern = GENRE_PATTERNS[filter]
    genres = self.class.genres
    return nil if genres.nil?

    genres.select { |genre| pattern&.match?(genre["name"].to_s) }.map { |genre| genre["code"] }
  end

  def search(genre_codes:, keyword:)
    cache_key = ["hotpepper/v2", @group_code, genre_codes.join("+"), keyword].join("/")

    Rails.cache.fetch(cache_key, expires_in: 1.day, skip_nil: true) do
      params = { lat: @lat, lng: @lon, range: RANGE, count: COUNT }
      params[:genre] = genre_codes.join(",") if genre_codes.any?
      params[:keyword] = keyword if keyword.present?

      self.class.request("gourmet", params)&.fetch("shop", [])&.map { |shop| simplify(shop) }
    end
  end

  # Keep only what midstop uses, so the cache stays small
  def simplify(shop)
    {
      "name" => shop["name"],
      "genre" => shop.dig("genre", "name"),
      "budget" => shop.dig("budget", "name"),
      "tagline" => shop["catch"],
      "photo" => shop.dig("photo", "pc", "m") || shop.dig("photo", "mobile", "l"),
      "url" => shop.dig("urls", "pc"),
      "open" => shop["open"],
      "address" => shop["address"],
      "lat" => shop["lat"].to_f,
      "lon" => shop["lng"].to_f
    }
  end

  def build_place(shop)
    meters = Geo.distance_km(@lat, @lon, shop["lat"], shop["lon"]) * 1000
    Place.new(
      name: shop["name"],
      category: category_for(shop["genre"].to_s),
      walk_minutes: [(meters / METERS_PER_MINUTE).ceil, 1].max,
      genre: shop["genre"],
      budget: shop["budget"],
      tagline: shop["tagline"],
      photo: shop["photo"],
      url: shop["url"],
      open: shop["open"],
      address: shop["address"],
      lat: shop["lat"],
      lon: shop["lon"]
    )
  end

  def category_for(genre_name)
    case genre_name
    when /居酒屋|バー|バル/ then "drinks"
    when /カフェ/ then "cafes"
    when /カラオケ/ then "karaoke"
    else "food"
    end
  end
end
