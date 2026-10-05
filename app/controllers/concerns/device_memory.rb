# Things midstop remembers per device, in signed cookies (no accounts needed).
module DeviceMemory
  extend ActiveSupport::Concern

  included do
    helper_method :home_station
  end

  private

  # { group_code: 2600303, name: "三軒茶屋", romaji: "Sangenjaya" }, or nil if not set
  def home_station
    return @home_station if defined?(@home_station)

    code = cookies.signed[:home_station].to_i
    label = Station.labels_for([ code ])[code] if code.positive?
    @home_station = label && label.merge(group_code: code)
  end

  def remember_home_station(group_code)
    cookies.permanent.signed[:home_station] = { value: group_code, httponly: true, same_site: :lax }
    @home_station = nil
    remove_instance_variable(:@home_station)
  end

  def forget_home_station
    cookies.delete(:home_station)
  end
end
