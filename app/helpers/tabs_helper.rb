module TabsHelper
  TABS = [
    { label: "Meet", path: :root_path, controllers: %w[meetups places], icon: :pin },
    { label: "Saved", path: :saved_path, controllers: %w[saved], icon: :star },
    { label: "Recent", path: :recent_path, controllers: %w[recents], icon: :clock },
    { label: "You", path: :you_path, controllers: %w[profiles], icon: :person }
  ].freeze

  ICONS = {
    pin: '<path d="M12 21s-7-6.2-7-11a7 7 0 0 1 14 0c0 4.8-7 11-7 11z"/><circle cx="12" cy="10" r="2.5"/>',
    star: '<path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8-4.3-4.1 5.9-.9z"/>',
    clock: '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
    person: '<circle cx="12" cy="8" r="3.5"/><path d="M5 20c1.2-3.6 3.8-5.5 7-5.5s5.8 1.9 7 5.5"/>'
  }.freeze

  def tab_bar_tabs
    TABS.map do |tab|
      tab.merge(href: public_send(tab[:path]), active: tab[:controllers].include?(controller_name))
    end
  end

  def tab_icon(name)
    tag.svg(ICONS.fetch(name).html_safe, viewBox: "0 0 24 24", class: "h-6 w-6", fill: "none",
            stroke: "currentColor", "stroke-width": 1.8, "stroke-linecap": "round", "stroke-linejoin": "round",
            "aria-hidden": true)
  end
end
