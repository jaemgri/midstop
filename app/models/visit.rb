# A place a crew went to together, logged with "we went here".
class Visit < ApplicationRecord
  belongs_to :crew, touch: true

  validates :place_name, presence: true, length: { maximum: 100 }
  validates :group_code, presence: true
  validates :visited_on, presence: true
  validate :links_are_web_addresses

  scope :recent_first, -> { order(visited_on: :desc, id: :desc) }

  private

  # Links come from the browser, so only allow real web addresses
  # (never javascript: or anything else that could run code when tapped)
  def links_are_web_addresses
    [url, photo].compact_blank.each do |link|
      errors.add(:base, :invalid) unless link.match?(%r{\Ahttps?://[^\s"'<>]+\z})
    end
  end
end
