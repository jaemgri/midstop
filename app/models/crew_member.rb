# One seat in a crew: a station, and (once claimed) the name of the person who sits there.
class CrewMember < ApplicationRecord
  belongs_to :crew

  validates :group_code, presence: true
  validates :name, presence: true, length: { maximum: 30 }, if: :claimed?

  def claimed? = token.present?

  # Claims the seat if it's still open. Returns the new secret token, or nil if someone got there first.
  def claim!(name)
    new_token = SecureRandom.base58(24)
    claimed = self.class.where(id: id, token: nil).update_all(name: name, token: new_token, updated_at: Time.current)
    claimed == 1 ? new_token : nil
  end

  def leave!
    update!(name: nil, token: nil)
  end
end
