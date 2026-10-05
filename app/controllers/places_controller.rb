class PlacesController < ApplicationController
  def show
    @group_code = params[:group_code].to_i
    @station = Station.labels_for([@group_code])[@group_code] or raise ActiveRecord::RecordNotFound

    @filter = params[:type].presence_in(NearbyPlaces::FILTERS.keys)
    @query = params[:q].to_s.strip.first(40)

    lat, lon = Station.center_of(@group_code)
    @places = NearbyPlaces.new(lat: lat, lon: lon, cache_key: "places/v2/#{@group_code}")
                          .call(filter: @filter, query: @query)
  end
end
