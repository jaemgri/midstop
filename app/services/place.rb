# A place to eat or drink near a station, from either Hot Pepper or OpenStreetMap.
# name, category and walk_minutes are always present; the rest depend on the source.
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
  :open,
  :address,
  :lat,
  :lon
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
    open: nil,
    address: nil,
    lat: nil,
    lon: nil
  )
    super
  end
end
