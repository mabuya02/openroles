class Tag < ApplicationRecord
  has_many :job_tags, dependent: :destroy
  has_many :jobs, through: :job_tags
  has_many :alerts_tags, dependent: :destroy
  has_many :alerts, through: :alerts_tags

  validates :name, presence: true, uniqueness: true

  # Scopes
  scope :popular, -> { joins(:jobs).group("tags.id").having("COUNT(jobs.id) > ?", 5) }
  scope :for_alerts, -> { joins(:alerts).distinct }

  # Normalize tag name before saving
  before_validation :normalize_name

  def to_param
    name.parameterize
  end

  private

  def normalize_name
    self.name = name.strip.downcase if name.present?
  end
end
