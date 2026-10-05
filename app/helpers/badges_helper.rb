module BadgesHelper
  FALLBACK_COLOR = "#5d6876"

  # A Tokyo-signage style badge: a white circle with a ring in the line's colour.
  def line_badge(badge, size: :md)
    color = badge.color || FALLBACK_COLOR
    label = [[badge.letters, badge.number].compact.join(" "), badge.line_name].compact_blank.join(", ")

    if size == :md
      tag.span(class: "inline-flex h-11 w-11 shrink-0 flex-col items-center justify-center rounded-full border-[3px] bg-white leading-none text-ink",
               style: "border-color: #{color}", role: "img", "aria-label": label, title: label) do
        safe_join([
          tag.span(badge.letters, class: "text-[10px] font-bold"),
          (tag.span(badge.number, class: "text-sm font-black tabular-nums") if badge.number)
        ].compact)
      end
    else
      tag.span(badge.letters,
               class: "inline-flex h-6 min-w-6 shrink-0 items-center justify-center rounded-full border-2 bg-white px-1 text-[10px] font-bold leading-none text-ink",
               style: "border-color: #{color}", role: "img", "aria-label": label, title: label)
    end
  end

  def line_badges(badges, size: :md, limit: nil)
    list = Array(badges)
    shown = limit ? list.first(limit) : list
    extra = list.size - shown.size

    safe_join([
      *shown.map { |badge| line_badge(badge, size: size) },
      (tag.span("+#{extra}", class: "self-center text-xs font-medium text-steel") if extra.positive?)
    ].compact)
  end
end
