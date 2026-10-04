# Ranks meeting stations so the longest trip in the group is as short as possible.
class MidpointFinder
  FIRST_TRAIN_WAIT = 3 # minutes of waiting for the first train, so totals feel realistic

  Result = Data.define(:group_code, :name, :romaji, :minutes) do
    def longest = minutes.max
    def total = minutes.sum
  end

  def initialize(group_codes, graph: TransitGraph.instance)
    @group_codes = group_codes
    @graph = graph
  end

  def call(limit: 5)
    times = @group_codes.map { |group| @graph.minutes_from(group) }
    reachable_by_all = times.map(&:keys).reduce(:&)

    ranked = reachable_by_all
      .map { |group| [group, times.map { |t| trip_minutes(t[group]) }] }
      .sort_by { |_, minutes| [minutes.max, minutes.sum] }
      .first(limit)

    labels = Station.labels_for(ranked.map(&:first))

    ranked.map do |group, minutes|
      label = labels[group]
      Result.new(group_code: group, name: label[:name], romaji: label[:romaji], minutes: minutes)
    end
  end

  private

  def trip_minutes(raw_minutes)
    minutes = raw_minutes.round
    minutes.zero? ? 0 : minutes + FIRST_TRAIN_WAIT
  end
end
