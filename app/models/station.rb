class Station < ApplicationRecord
  belongs_to :line, foreign_key: :line_code, primary_key: :code, optional: true

  Badge = Data.define(:letters, :number, :color, :line_name)

  HEX_COLOR = /\A#\h{6}\z/

  # { group_code => { name: "渋谷", romaji: "Shibuya" } } for a set of station groups
  def self.labels_for(group_codes)
    where(group_code: group_codes)
      .group(:group_code)
      .pluck(:group_code, Arel.sql("MIN(name)"), Arel.sql("MIN(name_romaji)"))
      .to_h { |group, name, romaji| [group, { name: name, romaji: romaji }] }
  end

  # Average position of every platform in a station group, as [lat, lon]
  def self.center_of(group_code)
    where(group_code: group_code).pick(Arel.sql("AVG(lat)"), Arel.sql("AVG(lon)"))
  end

  # The station closest to a point, as [group_code, lat, lon]
  def self.nearest_to(lat, lon)
    lon_scale = Math.cos(lat * Math::PI / 180)
    distance = sanitize_sql_array([
      "(lat - ?) * (lat - ?) + ((lon - ?) * ?) * ((lon - ?) * ?)",
      lat, lat, lon, lon_scale, lon, lon_scale
    ])
    order(Arel.sql(distance)).pick(:group_code, :lat, :lon)
  end

  # Matches kanji, kana or romaji. Names starting with the query come first, then bigger stations.
  def self.search(query, limit: 8)
    raw = query.to_s.strip
    return [] if raw.empty?

    kana = KanaRomanizer.to_hiragana(raw)
    key = KanaRomanizer.search_key(raw)

    columns = { name: raw, name_kana: kana }
    columns[:search_key] = key if key.present?

    values = {}
    contains = []
    starts = []
    columns.each do |column, term|
      escaped = sanitize_sql_like(term)
      values[:"#{column}_any"] = "%#{escaped}%"
      values[:"#{column}_start"] = "#{escaped}%"
      contains << "#{column} LIKE :#{column}_any"
      starts << "#{column} LIKE :#{column}_start"
    end

    prefix_first = sanitize_sql_array(["MAX(CASE WHEN #{starts.join(' OR ')} THEN 1 ELSE 0 END) DESC", values])

    where(contains.join(" OR "), values)
      .group(:group_code)
      .order(Arel.sql(prefix_first), Arel.sql("COUNT(*) DESC"))
      .limit(limit)
      .pluck(:group_code, Arel.sql("MIN(name)"), Arel.sql("MIN(name_romaji)"), Arel.sql("COUNT(*)"))
      .then do |groups|
        badges = badges_for(groups.map(&:first))
        groups.map do |group, name, romaji, lines|
          {
            group_code: group, name: name, romaji: romaji, lines: lines,
            badges: Array(badges[group]).first(4).map { |badge| { letters: badge.letters, color: badge.color } }
          }
        end
      end
  end

  # { group_code => [Badge, ...] }: one badge per line at each station, numbered ones first
  def self.badges_for(group_codes)
    joins(:line)
      .where(group_code: group_codes)
      .pluck(:group_code, :numbering, "lines.symbol", "lines.color", "lines.name")
      .group_by(&:first)
      .transform_values do |rows|
        rows.map { |_, numbering, symbol, color, line_name| build_badge(numbering, symbol, color, line_name) }
            .uniq { |badge| [badge.letters, badge.number] }
            .sort_by { |badge| [badge.number ? 0 : 1, badge.letters.to_s] }
      end
  end

  def self.build_badge(numbering, symbol, color, line_name)
    letters, number = numbering.to_s.match(/\A([A-Za-z]+)-?(\d+)\z/)&.captures
    letters ||= numbering.presence || symbol
    Badge.new(letters: letters, number: number, color: color.to_s.match?(HEX_COLOR) ? color : nil, line_name: line_name)
  end
  private_class_method :build_badge
end
