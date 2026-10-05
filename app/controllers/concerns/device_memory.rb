# Things midstop remembers per device, in signed cookies (no accounts needed).
module DeviceMemory
  extend ActiveSupport::Concern

  MAX_SAVED_SPOTS = 20
  MAX_SAVED_GROUPS = 10
  MAX_RECENTS = 15

  included do
    helper_method :home_station, :spot_saved?
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

  def write_cookie(name, value)
    cookies.permanent.signed[name] = { value: value, httponly: true, same_site: :lax }
  end
end
