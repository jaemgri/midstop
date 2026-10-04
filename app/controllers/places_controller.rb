class PlacesController < ApplicationController
  def show
    group_code = params[:group_code].to_i
    @station = Station.labels_for([group_code])[group_code] or raise ActiveRecord::RecordNotFound

    lat, lon = Station.center_of(group_code)
    @places = NearbyPlaces.new(lat: lat, lon: lon, cache_key: "places/v1/#{group_code}").call
  end
end
