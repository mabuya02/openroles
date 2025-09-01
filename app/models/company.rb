class Company < ApplicationRecord
  has_many :jobs, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: CompanyStatus::VALUES }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, and hyphens allowed" }
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp }, allow_blank: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :active, -> { where(status: CompanyStatus::ACTIVE) }
  scope :with_jobs, -> { joins(:jobs).distinct }

  def to_param
    slug
  end

  private

  def generate_slug
    base_slug = name.downcase.gsub(/[^a-z0-9\s]/, "").gsub(/\s+/, "-")
    candidate_slug = base_slug
    counter = 1

    while Company.exists?(slug: candidate_slug)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end
end
