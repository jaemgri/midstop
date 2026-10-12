class VisitsController < ApplicationController
  before_action :set_crew_and_seat

  def create
    visit = @crew.visits.find_or_initialize_by(
      group_code: params[:group_code].to_i,
      place_name: params[:place_name].to_s.strip.first(100),
      visited_on: Date.current
    )

    if visit.new_record?
      visit.assign_attributes(
        genre: params[:genre].to_s.first(50).presence,
        budget: params[:budget_band].to_s.first(30).presence,
        url: params[:url].presence,
        photo: params[:photo].presence,
        logged_by: @seat.name
      )
    end

    if visit.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(params[:button_id].to_s,
            partial: "visits/logged", locals: { button_id: params[:button_id].to_s })
        end
        format.html { redirect_to crew_path(@crew), notice: t(".logged", place: visit.place_name) }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @crew.visits.find(params[:id]).destroy
    redirect_to crew_path(@crew), notice: t(".removed")
  end

  private

  def set_crew_and_seat
    @crew = Crew.includes(:members).find_by!(token: crew_token_from(params[:crew_token]))
    @seat = my_seat_in(@crew) or head(:forbidden)
  end
end
