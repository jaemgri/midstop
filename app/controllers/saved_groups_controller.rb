class SavedGroupsController < ApplicationController
  def create
    requested = Array(params[:codes]).map(&:to_i).select(&:positive?).first(MeetupsController::MAX_PEOPLE)
    real = Station.where(group_code: requested).distinct.pluck(:group_code).to_set
    codes = requested.select { |code| real.include?(code) }
    return head(:unprocessable_entity) if codes.size < 2

    name = params[:name].to_s.strip.first(30).presence || "My group"
    group = { "id" => SecureRandom.alphanumeric(8), "name" => name, "codes" => codes }
    write_saved(groups: [group, *saved_groups])

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("save_group", partial: "saved_groups/saved", locals: { name: name }) }
      format.html { redirect_to saved_path, notice: "Saved #{name}" }
    end
  end

  def destroy
    write_saved(groups: saved_groups.reject { |group| group["id"] == params[:id] })

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("saved_group_#{params[:id]}") }
      format.html { redirect_to saved_path }
    end
  end
end
