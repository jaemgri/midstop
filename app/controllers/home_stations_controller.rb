class HomeStationsController < ApplicationController
  def update
    code = params[:group_code].to_i.nonzero? || Station.search(params[:name], limit: 1).first&.dig(:group_code)

    if code && Station.exists?(group_code: code)
      remember_home_station(code)
      redirect_to you_path, notice: "Home station saved"
    else
      redirect_to you_path, alert: "Couldn't find that station. Try picking it from the list."
    end
  end

  def destroy
    forget_home_station
    redirect_to you_path, notice: "Home station cleared"
  end
end
