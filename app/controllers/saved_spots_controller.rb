class SavedSpotsController < ApplicationController
  def create
    code = params[:group_code].to_i
    return head(:unprocessable_entity) unless Station.exists?(group_code: code)

    write_saved(spots: [code, *(saved_spot_codes - [code])])
    respond_with_button(code)
  end

  def destroy
    code = params[:group_code].to_i
    write_saved(spots: saved_spot_codes - [code])
    respond_with_button(code)
  end

  private

  # Turbo requests get just the updated star button (and the row removed on the Saved page).
  def respond_with_button(code)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("save_spot_#{code}", partial: "saved_spots/button", locals: { code: code }),
          (turbo_stream.remove("saved_spot_row_#{code}") unless spot_saved?(code))
        ].compact
      end
      format.html { redirect_back fallback_location: saved_path }
    end
  end
end
