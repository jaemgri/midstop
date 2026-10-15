class CrewPicksController < ApplicationController
  def show
    @crew = Crew.includes(:members).find_by!(token: crew_token_from(params[:crew_token]))
    return head(:forbidden) unless my_seat_in(@crew)

    @group_code = params[:group_code].to_i
    @station = Station.labels_for([@group_code])[@group_code] or raise ActiveRecord::RecordNotFound
    @visited = @crew.visits.where(group_code: @group_code).order(:visited_on).pluck(:place_name, :visited_on).to_h

    places = candidate_places
    return if places.nil? # @picks stays nil: "couldn't load"

    # Cached per crew, station, language and preferences. @crew.updated_at changes
    # whenever a visit is logged, so new history means fresh picks.
    cache_key = ["crew-picks/v1", @crew.id, @crew.updated_at.to_i, @group_code, I18n.locale, preferences.to_a.flatten.join(",")].join("/")

    chosen = Rails.cache.fetch(cache_key, expires_in: 6.hours, skip_nil: true) do
      CrewPicks.new(crew: @crew, places: places, group_code: @group_code, station_name: @station[:name],
                    preferences: preferences, locale: I18n.locale)
               .call&.map { |pick| [pick.place.name, pick.reason] }
    end

    @picks = chosen&.filter_map do |name, reason|
      place = places.find { |candidate| candidate.name == name }
      place && [place, reason]
    end
  end

  private

  # The same places the slide shows: favourites first, filtered by budget and walk
  def candidate_places
    lat, lon = Station.center_of(@group_code)
    options = { preferred: preferences[:vibes], max_walk: preferences[:walk] }

    places = if HotPepperPlaces.available?
      HotPepperPlaces.new(group_code: @group_code, lat: lat, lon: lon).call(**options, max_budget: preferences[:budget])
    end
    places ||= NearbyPlaces.new(lat: lat, lon: lon, cache_key: "places/v4/#{@group_code}").call(**options)

    places&.values&.flatten&.uniq(&:name)
  end
end
