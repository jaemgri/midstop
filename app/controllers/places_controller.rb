class PlacesController < ApplicationController
  def show
    @group_code = params[:group_code].to_i
    @station = Station.labels_for([@group_code])[@group_code] or raise ActiveRecord::RecordNotFound

    @filter = params[:type].presence_in(NearbyPlaces::FILTERS.keys)
    @query = params[:q].to_s.strip.first(40)

    lat, lon = Station.center_of(@group_code)
    options = { filter: @filter, query: @query, preferred: preferences[:vibes], max_walk: preferences[:walk] }

    if HotPepperPlaces.available?
      @places = HotPepperPlaces.new(group_code: @group_code, lat: lat, lon: lon).call(**options)
      @source = :hotpepper unless @places.nil?
    end

    if @places.nil?
      @places = NearbyPlaces.new(lat: lat, lon: lon, cache_key: "places/v4/#{@group_code}").call(**options)
      @source = :osm
    end
  end
end
