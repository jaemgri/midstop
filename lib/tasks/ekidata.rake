require "csv"

namespace :ekidata do
  desc "Import Tokyo-area lines, stations and segments from db/data/*.csv"
  task import: :environment do
    # Saitama, Chiba, Tokyo, Kanagawa
    PREFS = [11, 12, 13, 14].freeze
    dir = Rails.root.join("db/data")

    find_file = ->(prefix) do
      Dir[dir.join("#{prefix}*.csv")].max or abort "Missing #{prefix}*.csv in db/data"
    end
    read = ->(prefix) { CSV.foreach(find_file.(prefix), headers: true, encoding: "bom|utf-8") }

    stations = read.("station").filter_map do |row|
      next unless row["e_status"] == "0" && PREFS.include?(row["pref_cd"].to_i)

      {
        code: row["station_cd"].to_i,
        group_code: row["station_g_cd"].to_i,
        name: row["station_name"],
        name_romaji: row["station_name_r"],
        line_code: row["line_cd"].to_i,
        pref_code: row["pref_cd"].to_i,
        lat: row["lat"].to_f,
        lon: row["lon"].to_f
      }
    end

    station_codes = stations.map { |s| s[:code] }.to_set
    line_codes = stations.map { |s| s[:line_code] }.to_set

    lines = read.("line").filter_map do |row|
      next unless line_codes.include?(row["line_cd"].to_i)

      { code: row["line_cd"].to_i, name: row["line_name"], color: row["line_color_c"] }
    end

    segments = read.("join").filter_map do |row|
      from, to = row["station_cd1"].to_i, row["station_cd2"].to_i
      next unless station_codes.include?(from) && station_codes.include?(to)

      { line_code: row["line_cd"].to_i, from_code: from, to_code: to }
    end

    ActiveRecord::Base.transaction do
      Segment.delete_all
      Station.delete_all
      Line.delete_all

      Line.insert_all!(lines)
      Station.insert_all!(stations)
      Segment.insert_all!(segments)
    end

    puts "Imported #{lines.size} lines, #{stations.size} stations, #{segments.size} segments"
  end
end
