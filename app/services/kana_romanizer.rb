# Converts Japanese kana station readings into Hepburn-style romaji,
# and builds forgiving search keys so "tokyo", "Tōkyō" and "toukyou" all match.
module KanaRomanizer
  SINGLE = %w[
    あ a い i う u え e お o
    か ka き ki く ku け ke こ ko
    さ sa し shi す su せ se そ so
    た ta ち chi つ tsu て te と to
    な na に ni ぬ nu ね ne の no
    は ha ひ hi ふ fu へ he ほ ho
    ま ma み mi む mu め me も mo
    や ya ゆ yu よ yo
    ら ra り ri る ru れ re ろ ro
    わ wa ゐ i ゑ e を o ん n
    が ga ぎ gi ぐ gu げ ge ご go
    ざ za じ ji ず zu ぜ ze ぞ zo
    だ da ぢ ji づ zu で de ど do
    ば ba び bi ぶ bu べ be ぼ bo
    ぱ pa ぴ pi ぷ pu ぺ pe ぽ po
    ゔ vu ぁ a ぃ i ぅ u ぇ e ぉ o
  ].each_slice(2).to_h.freeze

  SMALL_Y = { "ゃ" => "a", "ゅ" => "u", "ょ" => "o" }.freeze

  module_function

  # "とうきょう" -> "Tokyo", "しんばし" -> "Shimbashi"
  def romanize(kana)
    chars = to_hiragana(kana.to_s).chars
    out = +""
    double_next = false
    i = 0

    while i < chars.size
      char = chars[i]
      nxt = chars[i + 1]

      if char == "っ" # small tsu doubles the next consonant: にっぽり -> nippori
        double_next = true
        i += 1
        next
      end

      syllable =
        if SMALL_Y.key?(nxt) && SINGLE[char]&.end_with?("i") # きょ -> kyo, しゃ -> sha
          i += 1
          stem = SINGLE[char].delete_suffix("i")
          stem.end_with?("sh", "ch", "j") ? stem + SMALL_Y[nxt] : stem + "y" + SMALL_Y[nxt]
        else
          SINGLE[char] || ""
        end

      unless syllable.empty?
        syllable = (syllable.start_with?("ch") ? "t" : syllable[0]) + syllable if double_next
        double_next = false
      end

      out << syllable
      i += 1
    end

    out = out.gsub(/n(?=[bmp])/, "m") # しんばし -> shimbashi
    simplify_long_vowels(out).capitalize
  end

  # Lowercase ASCII key for matching: strips macrons, spaces and punctuation.
  def search_key(text)
    ascii = text.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase.gsub(/[^a-z]/, "")
    simplify_long_vowels(ascii).gsub(/m(?=[bp])/, "n")
  end

    CHOME = {
    "一" => "いっちょうめ", "二" => "にちょうめ", "三" => "さんちょうめ",
    "四" => "よんちょうめ", "五" => "ごちょうめ", "六" => "ろくちょうめ",
    "七" => "ななちょうめ", "八" => "はっちょうめ", "九" => "きゅうちょうめ"
  }.freeze

  # Romanizes with a hyphen where the name contains another station's name:
  # 新宿三丁目 -> "Shinjuku-sanchome", 東中野 -> "Higashi-nakano"
  def romanize_name(name, kana, kana_by_name)
    parts = split_reading(name, to_hiragana(kana), kana_by_name)
    parts.map { |part| romanize(part).downcase }.join("-").capitalize
  end

  def split_reading(name, kana, kana_by_name)
    if (number = name[/([一二三四五六七八九])丁目\z/, 1]) && kana.end_with?(CHOME[number])
      return [kana.delete_suffix(CHOME[number]), CHOME[number]].reject(&:empty?)
    end

    (1...name.length).each do |i|
      head, tail = name[0...i], name[i..]

      head_kana = kana_by_name[head]
      if head_kana && kana.start_with?(head_kana) && kana.length > head_kana.length
        return [head_kana, kana.delete_prefix(head_kana)]
      end

      tail_kana = kana_by_name[tail]
      if tail_kana && kana.end_with?(tail_kana) && kana.length > tail_kana.length
        return [kana.delete_suffix(tail_kana), tail_kana]
      end
    end

    [kana]
  end

  def to_hiragana(text)
    text.tr("ァ-ヶ", "ぁ-ゖ")
  end

  def simplify_long_vowels(romaji)
    romaji.gsub("ou", "o").gsub("oo", "o").gsub("uu", "u")
  end
end
