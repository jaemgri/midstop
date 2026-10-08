# Things midstop remembers per device, in signed cookies (no accounts needed).
module DeviceMemory
  extend ActiveSupport::Concern

  MAX_SAVED_SPOTS = 20
  MAX_SAVED_GROUPS = 10
  MAX_RECENTS = 15
  MAX_CREWS = 20
  VIBES = NearbyPlaces::FILTERS.keys.freeze
  WALK_LIMITS = [3, 5].freeze
  RANKINGS = %w[fair fast].freeze
  BUDGETS = [2000, 3000, 4000, 5000].freeze

  included do
    helper_method :home_station, :spot_saved?, :preferences, :my_seat_in
  end

  private

  # --- Home station ---

  # { group_code: 2600303, name: "三軒茶屋", romaji: "Sangenjaya" }, or nil if not set
  def home_station
    return @home_station if defined?(@home_station)

    code = cookies.signed[:home_station].to_i
    label = Station.labels_for([code])[code] if code.positive?
    @home_station = label && label.merge(group_code: code)
  end

  def remember_home_station(group_code)
    write_cookie(:home_station, group_code)
    remove_instance_variable(:@home_station) if defined?(@home_station)
  end

  def forget_home_station
    cookies.delete(:home_station)
  end

  # --- Crews ---
  # Stored as { "crew_token" => "seat_token" } for every crew this device has a seat in

  def crew_seats
    raw = cookies.signed[:crews]
    raw.is_a?(Hash) ? raw : {}
  end

  def remember_crew_seat(crew, seat_token)
    others = crew_seats.except(crew.token)
    write_cookie(:crews, { crew.token => seat_token }.merge(others).first(MAX_CREWS).to_h)
  end

  def forget_crew_seat(crew)
    write_cookie(:crews, crew_seats.except(crew.token))
  end

  # This device's seat in the crew, or nil
  def my_seat_in(crew)
    seat_token = crew_seats[crew.token]
    return nil if seat_token.blank?

    crew.members.find { |seat| seat.claimed? && ActiveSupport::SecurityUtils.secure_compare(seat.token, seat_token) }
  end

  # --- Saved spots and groups ---
  # Stored together as { "spots" => [codes], "groups" => [{ "id", "name", "codes" }] }

  def saved_data
    @saved_data ||= cookies.signed[:saved].is_a?(Hash) ? cookies.signed[:saved] : {}
  end

  def saved_spot_codes
    Array(saved_data["spots"]).map(&:to_i)
  end

  def saved_groups
    Array(saved_data["groups"])
  end

  def spot_saved?(group_code)
    saved_spot_codes.include?(group_code.to_i)
  end

  def write_saved(spots: saved_spot_codes, groups: saved_groups)
    @saved_data = { "spots" => spots.first(MAX_SAVED_SPOTS), "groups" => groups.first(MAX_SAVED_GROUPS) }
    write_cookie(:saved, @saved_data)
  end
  # --- Recent searches ---
  # Stored as [{ "codes" => [...], "best" => group_code, "at" => "2026-10-05T14:00:00+09:00" }]

  def recent_searches
    Array(cookies.signed[:recents])
  end

  def remember_search(codes, best_code)
    same_group = codes.sort
    others = recent_searches.reject { |entry| Array(entry["codes"]).sort == same_group }
    entry = { "codes" => codes, "best" => best_code, "at" => Time.current.iso8601 }
    write_cookie(:recents, [entry, *others].first(MAX_RECENTS))
  end

  def forget_recents
    cookies.delete(:recents)
  end

  def preferences
    @preferences ||= begin
      raw = cookies.signed[:prefs].is_a?(Hash) ? cookies.signed[:prefs] : {}
      {
        vibes: Array(raw["vibes"]) & VIBES,
        walk: raw["walk"].to_i.presence_in(WALK_LIMITS),
        ranking: raw["ranking"].presence_in(RANKINGS) || "fair",
        budget: raw["budget"].to_i.presence_in(BUDGETS)
      }
    end
  end

  def remember_preferences(vibes:, walk:, ranking:, budget:)
    write_cookie(:prefs, { "vibes" => vibes, "walk" => walk, "ranking" => ranking, "budget" => budget })
    @preferences = nil
  end

  def write_cookie(name, value)
    cookies.permanent.signed[name] = { value: value, httponly: true, same_site: :lax }
  end
end
