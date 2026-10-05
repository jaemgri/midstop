# The Greater Tokyo train network as a weighted graph, built once and reused.
class TransitGraph
  TRANSFER_MINUTES = 5    # walking between platforms + waiting
  MINUTES_PER_KM = 1.8    # ~33 km/h average, including stops
  MIN_RIDE_MINUTES = 2    # even very close stations take a couple of minutes

  def self.instance
    @instance ||= new
  end

  def self.reset!
    @instance = nil
  end

  def initialize
    @group_of = {}
    @line_of = {}
    @codes_in_group = Hash.new { |hash, key| hash[key] = [] }
    @coords = {}

    Station.pluck(:code, :group_code, :line_code, :lat, :lon).each do |code, group, line, lat, lon|
      @group_of[code] = group
      @line_of[code] = line
      @codes_in_group[group] << code
      @coords[code] = [lat, lon]
    end

    @edges = Hash.new { |hash, key| hash[key] = [] }

    Segment.pluck(:from_code, :to_code).each do |a, b|
      minutes = ride_minutes(@coords[a], @coords[b])
      @edges[a] << [b, minutes]
      @edges[b] << [a, minutes]
    end

    @codes_in_group.each_value do |codes|
      codes.combination(2).each do |a, b|
        @edges[a] << [b, TRANSFER_MINUTES]
        @edges[b] << [a, TRANSFER_MINUTES]
      end
    end
  end

  # Quickest minutes from one station group to every reachable station group.
  def minutes_from(group_code)
    best, = dijkstra(@codes_in_group.fetch(group_code))

    best.each_with_object({}) do |(code, minutes), by_group|
      group = @group_of[code]
      by_group[group] = minutes if minutes < by_group.fetch(group, Float::INFINITY)
    end
  end

  # The quickest route between two station groups, as a list of [lat, lon] points.
  def path_between(from_group, to_group)
    route_codes(from_group, to_group).map { |code| @coords[code] }
  end

  # The quickest route split into legs, one per train ridden:
  # [{ line_code: 11302, points: [[lat, lon], ...] }, ...]
  def legs_between(from_group, to_group)
    legs = []

    route_codes(from_group, to_group).each_cons(2) do |a, b|
      next if @group_of[a] == @group_of[b] # changing platforms inside a station, not a ride

      line = @line_of[b]
      if legs.last && legs.last[:line_code] == line && legs.last[:points].last == @coords[a]
        legs.last[:points] << @coords[b]
      else
        legs << { line_code: line, points: [@coords[a], @coords[b]] }
      end
    end

    legs
  end

  private

  # Station codes along the quickest route, or [] if there's no route.
  def route_codes(from_group, to_group)
    targets = @codes_in_group.fetch(to_group).to_set
    _, previous, reached = dijkstra(@codes_in_group.fetch(from_group), targets: targets)
    return [] unless reached

    path = [reached]
    path.unshift(previous[path.first]) while previous.key?(path.first)
    path
  end

  # Classic Dijkstra. With targets, it stops as soon as it reaches one of them.
  def dijkstra(sources, targets: nil)
    best = sources.to_h { |code| [code, 0.0] }
    previous = {}
    heap = MinHeap.new
    sources.each { |code| heap.push(0.0, code) }

    until heap.empty?
      minutes, code = heap.pop
      next if minutes > best[code] # stale entry, we already found a faster way
      return [best, previous, code] if targets&.include?(code)

      @edges[code].each do |neighbour, cost|
        candidate = minutes + cost
        next unless candidate < best.fetch(neighbour, Float::INFINITY)

        best[neighbour] = candidate
        previous[neighbour] = code
        heap.push(candidate, neighbour)
      end
    end

    [best, previous, nil]
  end

  def ride_minutes(a, b)
    [MIN_RIDE_MINUTES, (Geo.distance_km(*a, *b) * MINUTES_PER_KM).round(1)].max
  end
end
