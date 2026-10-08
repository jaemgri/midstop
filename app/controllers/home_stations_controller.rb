class HomeStationsController < ApplicationController
  def update
    code = params[:group_code].to_i.nonzero? || Station.search(params[:name], limit: 1).first&.dig(:group_code)

    if code && Station.exists?(group_code: code)
      remember_home_station(code)
      redirect_to you_path, notice: t(".saved")
    else
      redirect_to you_path, alert: t(".not_found")
    end
  end

  def destroy
    forget_home_station
    redirect_to you_path, notice: t(".cleared")
  end
end
