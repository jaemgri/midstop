# Ranks meeting stations so the longest trip in the group is as short as possible.
class MidpointFinder
  Result = Data.define(:group_code, :name, :minutes) do
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
      .map { |group| [group, times.map { |t| t[group].round }] }
      .sort_by { |_, minutes| [minutes.max, minutes.sum] }
      .first(limit)

    names = Station.where(group_code: ranked.map(&:first))
                   .group(:group_code)
                   .pluck(:group_code, Arel.sql("MIN(name)"))
                   .to_h

    ranked.map { |group, minutes| Result.new(group_code: group, name: names[group], minutes: minutes) }
  end
end
