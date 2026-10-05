class SavedController < ApplicationController
  def index
    @spots = saved_spot_codes
    @groups = saved_groups
    @labels = Station.labels_for((@spots + @groups.flat_map { |group| group["codes"] }).uniq)
  end
end
