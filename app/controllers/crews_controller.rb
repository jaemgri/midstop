class CrewsController < ApplicationController
  before_action :load_stations, only: [:new, :create]

  def new
    @crew = Crew.new
  end

  def create
    @crew = Crew.new(name: params[:crew_name].to_s.strip.first(40))
    @codes.each { |code| @crew.members.build(group_code: code) }

    mine = @crew.members[params[:seat].to_i]
    your_name = params[:your_name].to_s.strip.first(30)

    if mine && your_name.present?
      mine.name = your_name
      mine.token = SecureRandom.base58(24)
    end

    if mine&.claimed? && @crew.save
      remember_crew_seat(@crew, mine.token)
      redirect_to crew_path(@crew), notice: t(".created")
    else
      @error = t(".invalid")
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @crew = Crew.includes(:members).find_by!(token: crew_token_from(params[:token]))
    @visits = @crew.visits.recent_first.limit(50)
    @labels = Station.labels_for([*@crew.station_codes, *@visits.map(&:group_code)].uniq)
    @my_seat = my_seat_in(@crew)
  end

  private

  # The stations from the search this crew is being made from
  def load_stations
    codes = Array(params[:from]).map(&:to_i).select(&:positive?).first(Crew::MAX_SEATS)
    @labels = Station.labels_for(codes)
    @codes = codes.select { |code| @labels.key?(code) }
    redirect_to root_path if @codes.size < 2
  end
end
