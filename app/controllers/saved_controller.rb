class SavedController < ApplicationController
  def index
    @spots = saved_spot_codes
    @groups = saved_groups
    @labels = Station.labels_for((@spots + @groups.flat_map { |group| group["codes"] }).uniq)
    @crews = Crew.includes(:members).where(token: crew_seats.keys).order(updated_at: :desc)
  end

end
