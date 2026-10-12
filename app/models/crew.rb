class Crew < ApplicationRecord
  MAX_SEATS = 10

  has_secure_token :token
  has_many :members, -> { order(:id) }, class_name: "CrewMember", dependent: :destroy, inverse_of: :crew
  has_many :visits, dependent: :destroy

  validates :name, presence: true, length: { maximum: 40 }
  validates :members, length: { minimum: 2, maximum: MAX_SEATS }

  # Crew links use the secret token, not the database id: /crews/aB3x…
  def to_param = token

  def station_codes = members.map(&:group_code)
end
