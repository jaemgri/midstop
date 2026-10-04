class StationsController < ApplicationController
  def index
    render json: Station.search(params[:q])
  end
end
