module StationsHelper
  # How to name a station in the current language: kanji in Japanese, romaji in English
  def station_label(label)
    return "" if label.nil?

    I18n.locale == :ja ? label[:name] : (label[:romaji].presence || label[:name])
  end

  # A list of stations joined naturally: "Yoga, Shibuya, and Ebisu" or "用賀、渋谷、恵比寿"
  def station_list(labels_by_code, codes)
    codes.filter_map { |code| labels_by_code[code] }.map { |label| station_label(label) }.to_sentence
  end
end
