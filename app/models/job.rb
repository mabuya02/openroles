class Job < ApplicationRecord
  belongs_to :company
  has_one :job_metadatum, dependent: :destroy
  has_many :job_tags, dependent: :destroy
  has_many :tags, through: :job_tags
  has_many :applications, dependent: :destroy
  has_many :saved_jobs, dependent: :destroy

  validates :status, inclusion: { in: JobStatus::VALUES }
  validates :employment_type, inclusion: { in: EmploymentType::VALUES }

  # Validations for new fields
  validates :source, presence: true
  validates :external_id, uniqueness: { scope: :source }, allow_blank: true
  validates :fingerprint, uniqueness: true, allow_blank: true
  validates :salary_min, :salary_max, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :apply_url, format: { with: URI::DEFAULT_PARSER.make_regexp }, allow_blank: true
  validates :currency, presence: true, inclusion: { in: %w[USD EUR GBP CAD AUD JPY CHF SEK NOK DKK] }

  # Scopes for search and filtering
  scope :published, -> { where(status: JobStatus::OPEN) }
  scope :closed_or_expired, -> { where(status: [ JobStatus::CLOSED, JobStatus::EXPIRED ]) }
  scope :recently_updated, -> { where(updated_at: 1.week.ago..Time.current) }
  scope :from_source, ->(source) { where(source: source) }
  scope :with_salary_range, ->(min, max) { where(salary_min: min..max).or(where(salary_max: min..max)) }
  scope :posted_after, ->(date) { where("jobs.posted_at >= ?", date) }
  scope :posted_before, ->(date) { where("jobs.posted_at <= ?", date) }
  scope :remote_friendly, -> { where("jobs.location ILIKE ? OR jobs.location ILIKE ?", "%remote%", "%worldwide%") }
  scope :with_salary, -> { where.not(salary_min: nil).or(where.not(salary_max: nil)) }

  # Full-text search scope
  scope :search, ->(query) { where("jobs.search_vector @@ plainto_tsquery('english', ?)", query) }
  scope :fuzzy_search, ->(query) { where("jobs.title % ? OR jobs.description % ?", query, query) }

  # Callbacks
  before_validation :generate_fingerprint, if: -> { external_id.blank? }
  before_validation :set_posted_at, if: -> { posted_at.blank? }

  # Check if job is remote-friendly
  def remote_friendly?
    location.to_s.downcase.match?(/remote|worldwide|anywhere/)
  end

  private

  def generate_fingerprint
    return if title.blank? || company.blank?

    content = [ title, company.name, location, description ].compact.join("|")
    self.fingerprint = Digest::SHA256.hexdigest(content)
  end

  def set_posted_at
    self.posted_at = created_at || Time.current
  end
end
