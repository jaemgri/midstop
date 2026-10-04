module Geo
  EARTH_RADIUS_KM = 6371

  module_function

  # Straight-line distance between two lat/lon points (haversine formula)
  def distance_km(lat1, lon1, lat2, lon2)
    rad = Math::PI / 180
    dlat = (lat2 - lat1) * rad
    dlon = (lon2 - lon1) * rad
    h = Math.sin(dlat / 2)**2 + Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin(dlon / 2)**2
    EARTH_RADIUS_KM * 2 * Math.asin(Math.sqrt(h))
  end
end
