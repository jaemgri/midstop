class Station < ApplicationRecord
  # { group_code => { name: "渋谷", romaji: "Shibuya" } } for a set of station groups
  def self.labels_for(group_codes)
    where(group_code: group_codes)
      .group(:group_code)
      .pluck(:group_code, Arel.sql("MIN(name)"), Arel.sql("MIN(name_romaji)"))
      .to_h { |group, name, romaji| [group, { name: name, romaji: romaji }] }
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
      .map { |group, name, romaji, lines| { group_code: group, name: name, romaji: romaji, lines: lines } }
  end
end
