class CrewSeatsController < ApplicationController
  before_action :set_crew_and_seat

  # Claim an open seat ("that's me")
  def update
    name = params[:name].to_s.strip.first(30)

    if name.blank?
      redirect_to crew_path(@crew), notice: t(".need_name")
    elsif my_seat_in(@crew)
      redirect_to crew_path(@crew), notice: t(".already_in")
    elsif (seat_token = @seat.claim!(name))
      remember_crew_seat(@crew, seat_token)
      redirect_to crew_path(@crew), notice: t(".welcome", crew: @crew.name)
    else
      redirect_to crew_path(@crew), notice: t(".taken")
    end
  end

  # Leave your own seat (it opens up again)
  def destroy
    if my_seat_in(@crew)&.id == @seat.id
      @seat.leave!
      forget_crew_seat(@crew)
      redirect_to saved_path, notice: t(".left", crew: @crew.name)
    else
      head :forbidden
    end
  end

  private

  def set_crew_and_seat
    @crew = Crew.includes(:members).find_by!(token: crew_token_from(params[:crew_token]))
    @seat = @crew.members.find { |seat| seat.id == params[:id].to_i } or raise ActiveRecord::RecordNotFound
  end
end
