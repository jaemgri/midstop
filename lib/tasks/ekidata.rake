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

    # Hiragana readings from station_database (CC BY 4.0), keyed by Ekidata station code
    kana_by_code = read.("kana_station").to_h { |row| [row["code"].to_i, row["name_kana"]] }

    stations = read.("station").filter_map do |row|
      next unless row["e_status"] == "0" && PREFS.include?(row["pref_cd"].to_i)

      code = row["station_cd"].to_i
      kana = kana_by_code[code]
      romaji = kana.present? ? KanaRomanizer.romanize(kana) : nil

      {
        code: code,
        group_code: row["station_g_cd"].to_i,
        name: row["station_name"],
        name_kana: kana,
        name_romaji: romaji,
        search_key: romaji && KanaRomanizer.search_key(romaji),
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

    missing = stations.count { |s| s[:name_kana].nil? }
    puts "Imported #{lines.size} lines, #{stations.size} stations, #{segments.size} segments"
    puts "#{missing} stations have no reading (still searchable in kanji)" if missing.positive?
  end
end
