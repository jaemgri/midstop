module PlacesHelper
  # The Hot Pepper page when we have one, otherwise a Google Maps search near the station
  def place_link(place, station_name)
    place.url.presence ||
      "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode("#{place.name} #{station_name}")}"
  end

  # Opens Google Maps on the place (the app on phones that have it)
  def place_map_link(place)
    query = place.address.present? ? "#{place.name} #{place.address}" : "#{place.lat},#{place.lon}"
    "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(query)}"
  end

  GENRES_EN = {
    "居酒屋" => "izakaya",
    "ダイニングバー・バル" => "dining bar",
    "バー・カクテル" => "bar",
    "ラーメン" => "ramen",
    "カフェ・スイーツ" => "café & sweets",
    "カラオケ・パーティ" => "karaoke & party",
    "和食" => "Japanese",
    "洋食" => "Western",
    "イタリアン・フレンチ" => "Italian & French",
    "中華" => "Chinese",
    "焼肉・ホルモン" => "yakiniku",
    "韓国料理" => "Korean",
    "アジア・エスニック料理" => "Asian",
    "各国料理" => "international",
    "お好み焼き・もんじゃ" => "okonomiyaki",
    "創作料理" => "fusion",
    "その他グルメ" => "other"
  }.freeze

  # Order matters: longer phrases first, so 祝前日 is replaced before 日 on its own
  HOURS_EN = [
    ["祝前日", "day before holidays"], ["祝後日", "day after holidays"], ["祝日", "holidays"],
    ["平日", "weekdays"], ["毎日", "every day"], ["不定休", "irregular days off"],
    ["料理L.O.", "food last order"], ["ドリンクL.O.", "drinks last order"], ["L.O.", "last order"],
    ["ランチ", "lunch"], ["ディナー", "dinner"],
    ["月", "Mon"], ["火", "Tue"], ["水", "Wed"], ["木", "Thu"], ["金", "Fri"], ["土", "Sat"], ["日", "Sun"],
    ["～", "–"], ["〜", "–"], ["、", ", "], ["（", " ("], ["）", ")"], ["：", ":"], ["　", " "]
  ].freeze

  def place_genre(genre)
    return genre if genre.blank? || I18n.locale == :ja
    GENRES_EN.fetch(genre, genre)
  end

  # "1501～2000円" → "¥1,501–2,000"
  def place_budget(budget)
    return budget if budget.blank? || I18n.locale == :ja

    text = budget.delete("円").gsub(/[～〜]/, "–").gsub(/\d+/) { |n| number_with_delimiter(n) }
    "¥#{text}"
  end

  # "月～日、祝日: 16:00～翌5:00" → "Mon–Sun, holidays: 16:00–5:00 (next day)"
  def place_hours(hours)
    return hours if hours.blank? || I18n.locale == :ja

    text = hours.gsub(/翌\s*(\d{1,2}:\d{2})/) { "#{$1} (next day)" }
    HOURS_EN.each { |japanese, english| text = text.gsub(japanese, english) }
    text.squish
  end
end
