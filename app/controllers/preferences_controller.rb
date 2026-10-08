class PreferencesController< ApplicationController
  def update
    remember_preferences(
      vibes: Array(params[:vibes]) & DeviceMemory::VIBES,
      walk: params[:walk].to_i.presence_in(DeviceMemory::WALK_LIMITS),
      ranking: params[:ranking].presence_in(DeviceMemory::RANKINGS) || "fair"
    )
    redirect_to you_path, notice: t(".saved")
  end
end
