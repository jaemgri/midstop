class SpotsController < ApplicationController
  def show
    @group_code = params[:group_code].to_i
    @label = Station.labels_for([@group_code])[@group_code] or raise ActiveRecord::RecordNotFound
    @badges = Station.badges_for([@group_code])
  end
end
