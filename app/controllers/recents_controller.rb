class RecentsController < ApplicationController
  def index
    @recents = recent_searches
    codes = @recents.flat_map { |entry| Array(entry["codes"]) + [entry["best"]] }.compact.uniq
    @labels = Station.labels_for(codes)
  end

  def clear
    forget_recents
    redirect_to recent_path, notice: "Recent searches cleared"
  end
end
