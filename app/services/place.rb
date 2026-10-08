# A place to eat or drink near a station, from either Hot Pepper or OpenStreetMap.
# Only name, category and walk_minutes are always present; the rest come from Hot Pepper.
Place = Data.define(
  :name,
  :category,
  :walk_minutes,
  :name_en,
  :genre,
  :budget,
  :tagline,
  :photo,
  :url,
  :open
) do
  def initialize(
    name:,
    category:,
    walk_minutes:,
    name_en: nil,
    genre: nil,
    budget: nil,
    tagline: nil,
    photo: nil,
    url: nil,
    open: nil
  )
    super
  end
end
