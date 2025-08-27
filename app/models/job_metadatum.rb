class JobMetadata < ApplicationRecord
  belongs_to :job

  validates :twitter_card_type, inclusion: { in: TwitterCardType::VALUES }, allow_nil: true
end
