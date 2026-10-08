require "net/http"

# Finds food, cafés, bars and karaoke near a point using OpenStreetMap's Overpass API.
# Everything nearby is fetched once and cached; chips and keyword searches filter that list.
# Returns plain IDs ("food", "cafes"…); views translate them.
class NearbyPlaces
  ENDPOINTS = [
    URI("https://overpass-api.de/api/interpreter"),
    URI("https://overpass.private.coffee/api/interpreter")
  ].freeze
  USER_AGENT = "midstop/1.0 (https://github.com/jaemgri/midstop)"
  RADIUS_METERS = 600
  METERS_PER_MINUTE = 80 # the standard walking pace in Japanese property listings
  PER_CATEGORY = 5
  MAX_FILTERED = 15
  CATEGORY_ORDER = %w[food cafes drinks karaoke].freeze

  # Izakaya are tagged inconsistently in OpenStreetMap, so also match on common words and chain names
  IZAKAYA_NAMES = /居酒屋|酒場|炉端|ろばた|焼鳥|焼き鳥|やきとり|串カツ|串揚|立ち飲み|立飲み|鳥貴族|磯丸水産|鳥メロ|塚田農場|白木屋|魚民|笑笑|金の蔵|はなの舞|庄や|晩杯屋|天狗|つぼ八/

  FILTERS = {
    "izakaya" => ->(item) {
      item["cuisine"].to_s.match?(/izakaya|yakitori|kushikatsu|robatayaki/) ||
        item["amenity"] == "pub" ||
        item["name"].match?(IZAKAYA_NAMES)
    },
    "bars" => ->(item) { %w[bar pub].include?(item["amenity"]) },
    "ramen" => ->(item) { item["cuisine"].to_s.match?(/ramen|noodle/) || item["name"].match?(/ラーメン|らーめん|拉麺/) },
    "cafes" => ->(item) { item["amenity"] == "cafe" },
    "karaoke" => ->(item) { item["amenity"] == "karaoke_box" || item["name"].match?(/カラオケ|karaoke/i) }
  }.freeze

  Place = Data.define(:name, :name_en, :category, :walk_minutes)

  def initialize(lat:, lon:, cache_key:)
    @lat = lat
    @lon = lon
    @cache_key = cache_key
  end

  # Returns { "heading_id" => [Place, ...], ... }, or nil if Overpass couldn't be reached.
  def call(filter: nil, query: nil, preferred: [], max_walk: nil)
    raw = Rails.cache.fetch(@cache_key, expires_in: 1.week, skip_nil: true) { fetch }
    return nil if raw.nil?

    items = raw
    items = items.select(&FILTERS[filter]) if FILTERS.key?(filter)

    keyword = query.to_s.strip.downcase
    if keyword.present?
      items = items.select do |item|
        [item["name"], item["name_en"], item["cuisine"]].compact.any? { |text| text.downcase.include?(keyword) }
      end
    end

    pairs = items.map { |item| [item, build_place(item)] }.sort_by { |_, place| place.walk_minutes }
    pairs = pairs.select { |_, place| place.walk_minutes <= max_walk } if max_walk
    places = pairs.map(&:last)

    if filter || keyword.present?
      heading = FILTERS.key?(filter) ? filter : "results"
      return places.empty? ? {} : { heading => places.first(MAX_FILTERED) }
    end

    grouped = places.group_by(&:category)
                    .transform_values { |list| list.first(PER_CATEGORY) }
                    .sort_by { |category, _| CATEGORY_ORDER.index(category) || 99 }
                    .to_h

    picks = pairs.select { |item, _| preferred.any? { |vibe| FILTERS[vibe]&.call(item) } }.map(&:last).first(8)
    picks.any? ? { "for_you" => picks }.merge(grouped) : grouped
  end

  private

  def fetch
    query = <<~QL
      [out:json][timeout:20];
      nwr["name"]["amenity"~"^(cafe|restaurant|fast_food|bar|pub|karaoke_box)$"](around:#{RADIUS_METERS},#{@lat},#{@lon});
      out center 500;
    QL

    ENDPOINTS.each do |endpoint|
      elements = request_elements(endpoint, query)
      return elements.filter_map { |element| parse(element) } if elements
    end

    nil
  end

  # The elements from one Overpass server, or nil if that server failed
  def request_elements(endpoint, query)
    http = Net::HTTP.new(endpoint.host, endpoint.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 25

    request = Net::HTTP::Post.new(endpoint)
    request["User-Agent"] = USER_AGENT
    request.set_form_data(data: query)

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("NearbyPlaces: #{endpoint.host} answered HTTP #{response.code}")
      return nil
    end

    JSON.parse(response.body).fetch("elements", [])
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, JSON::ParserError => e
    Rails.logger.warn("NearbyPlaces: #{endpoint.host} failed: #{e.class}: #{e.message}")
    nil
  end

  def parse(element)
    tags = element["tags"] || {}
    lat = element["lat"] || element.dig("center", "lat")
    lon = element["lon"] || element.dig("center", "lon")
    return nil if tags["name"].blank? || lat.nil? || lon.nil?

    {
      "name" => tags["name"],
      "name_en" => tags["name:en"],
      "amenity" => tags["amenity"],
      "cuisine" => tags["cuisine"],
      "category" => category_for(tags),
      "lat" => lat,
      "lon" => lon
    }
  end

  def category_for(tags)
    case tags["amenity"]
    when "cafe" then "cafes"
    when "karaoke_box" then "karaoke"
    when "bar", "pub" then "drinks"
    else tags["cuisine"].to_s.include?("izakaya") ? "drinks" : "food"
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
