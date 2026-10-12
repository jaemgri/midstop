class ApplicationController < ActionController::Base
  include DeviceMemory
  include Localization
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end

private

  # Crew tokens are letters and numbers only, so anything after them
  # (like invite text pasted along with the link) is ignored.
  def crew_token_from(value)
    value.to_s[/\A[A-Za-z0-9]+/]
  end

  def crew_in_context
    return nil if params[:crew].blank?

    crew = Crew.includes(:members).find_by(token: crew_token_from(params[:crew]))
    crew if crew && my_seat_in(crew)
  end
