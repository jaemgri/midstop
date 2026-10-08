module RecentsHelper
  # "today", "yesterday", or a short date like "5 Oct" / "10月5日"
  def relative_day(iso_time)
    time = Time.zone.parse(iso_time.to_s)
    return "" if time.nil?

    case time.to_date
    when Date.current then t("relative_day.today")
    when Date.yesterday then t("relative_day.yesterday")
    else l(time.to_date, format: :short_day)
    end
  end
end
