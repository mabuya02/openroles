class UserProfile < ApplicationRecord
  belongs_to :user
  has_many :applications, foreign_key: :resume_id

end
