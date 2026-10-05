class StationsController < ApplicationController
  MAX_DISTANCE_KM = 3
  METERS_PER_MINUTE = 80

  def index
    render json: Station.search(params[:q])
  end

  def nearest
    lat = Float(params[:lat], exception: false)
    lon = Float(params[:lon], exception: false)
    return head(:bad_request) unless lat&.between?(-90, 90) && lon&.between?(-180, 180)

    code, station_lat, station_lon = Station.nearest_to(lat, lon)
    distance_km = Geo.distance_km(lat, lon, station_lat, station_lon) if code
    return head(:not_found) if code.nil? || distance_km > MAX_DISTANCE_KM

    label = Station.labels_for([code])[code]
    render json: {
      group_code: code,
      name: label[:name],
      romaji: label[:romaji],
      walk_minutes: (distance_km * 1000 / METERS_PER_MINUTE).ceil
    }
  end
end
