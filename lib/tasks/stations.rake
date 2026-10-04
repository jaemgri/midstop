require "csv"

namespace :stations do
  desc "Import Greater Tokyo stations, lines and segments from station_database (CC BY 4.0)"
  task import: :environment do
    PREFS = [11, 12, 13, 14].freeze # Saitama, Chiba, Tokyo, Kanagawa
    dir = Rails.root.join("db/data/station_database")
    read = ->(file) { CSV.foreach(dir.join(file), headers: true, encoding: "bom|utf-8") }

    all_stations = read.("station.csv").to_h { |row| [row["code"].to_i, row] }

    # Every station's reading by name, used to hyphenate compound names like Shinjuku-sanchome
    kana_by_name = all_stations.each_value.with_object({}) do |row, map|
      map[row["original_name"]] ||= row["name_kana"]
    end

    tokyo = all_stations.select { |_, row| row["closed"] == "0" && PREFS.include?(row["prefecture"].to_i) }
    open_lines = read.("line.csv").select { |row| row["closed"] == "0" }.to_h { |row| [row["code"].to_i, row] }

    # Each line's Tokyo-area stations, in order: { line_code => [[index, station_code], ...] }
    order = Hash.new { |hash, key| hash[key] = [] }
    read.("register.csv").each do |row|
      line_code = row["line_code"].to_i
      station_code = row["station_code"].to_i
      next unless open_lines.key?(line_code) && tokyo.key?(station_code)

      order[line_code] << [row["index"].to_i, station_code]
    end
    order.each_value(&:sort!)

    # One Station row per station per line. code is unique per line; group_code is the station itself.
    stations = order.flat_map do |line_code, entries|
      entries.map do |index, station_code|
        row = tokyo[station_code]
        name = row["original_name"]
        romaji = KanaRomanizer.romanize_name(name, row["name_kana"], kana_by_name)

        {
          code: line_code * 1000 + index,
          group_code: station_code,
          name: name,
          name_kana: row["name_kana"],
          name_romaji: romaji,
          search_key: KanaRomanizer.search_key(romaji),
          line_code: line_code,
          pref_code: row["prefecture"].to_i,
          lat: row["lat"].to_f,
          lon: row["lng"].to_f
        }
      end
    end

    # Neighbouring stations on each line, then the hand-written fixes for loops and branches
    pairs = Set.new
    order.each do |line_code, entries|
      entries.each_cons(2) { |(_, a), (_, b)| pairs << [line_code, a, b] }
    end

    code_by_name = tokyo.to_h { |code, row| [row["name"], code] }
    resolve = ->(line, a, b) { [line, code_by_name.fetch(a), code_by_name.fetch(b)] }
    fixes = YAML.load_file(Rails.root.join("config/line_fixes.yml"))

    fixes.fetch("remove", []).each do |line, a, b|
      line, a, b = resolve.(line, a, b)
      pairs.delete([line, a, b])
      pairs.delete([line, b, a])
    end
    fixes.fetch("add", []).each { |line, a, b| pairs << resolve.(line, a, b) }

    node = stations.to_h { |s| [[s[:line_code], s[:group_code]], s[:code]] }
    segments = pairs.filter_map do |line, a, b|
      from = node[[line, a]]
      to = node[[line, b]]
      { line_code: line, from_code: from, to_code: to } if from && to
    end

    lines = order.keys.map do |code|
      row = open_lines[code]
      { code: code, name: row["name"], color: row["color"] }
    end

    ActiveRecord::Base.transaction do
      Segment.delete_all
      Station.delete_all
      Line.delete_all

      Line.insert_all!(lines)
      Station.insert_all!(stations)
      Segment.insert_all!(segments)
    end

    puts "Imported #{lines.size} lines, #{order.values.sum(&:size)} line stops at #{stations.map { |s| s[:group_code] }.uniq.size} stations, #{segments.size} segments"
  end
end
