module RecentsHelper
  # "Today", "Yesterday", or a short date like "5 Oct"
  def relative_day(iso_time)
    time = Time.zone.parse(iso_time.to_s)
    return "" if time.nil?

    case time.to_date
    when Date.current then "Today"
    when Date.yesterday then "Yesterday"
    else time.strftime("%-d %b")
    end
  end
end
