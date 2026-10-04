class MeetupsController < ApplicationController
  MAX_PEOPLE = 8

  def new
  end

  def show
    @group_codes = resolve_stations.first(MAX_PEOPLE)

    if @group_codes.size < 2
      redirect_to root_path, alert: "add at least two stations we can find"
      return
    end

    # If anything was typed rather than picked, redirect to a clean, shareable URL of codes only
    if params[:names].present?
      redirect_to meet_path(from: @group_codes)
      return
    end

    @origins = Station.labels_for(@group_codes)
    @results = MidpointFinder.new(@group_codes).call(limit: 5)
  rescue KeyError
    redirect_to root_path, alert: "couldn't find one of those stations, try picking it again"
  end

  private

  # Each form row sends a picked code (from[]) and the typed text (names[]).
  # Use the picked code if there is one, otherwise the best match for the text.
  def resolve_stations
    codes = Array(params[:from])
    names = Array(params[:names])

    codes.zip(names).filter_map do |code, name|
      code.to_i.nonzero? || Station.search(name, limit: 1).first&.dig(:group_code)
    end
  end
end
