class Job < ApplicationRecord
  include PgSearch::Model

  belongs_to :company
  has_one :job_metadatum, dependent: :destroy
  has_many :job_tags, dependent: :destroy
  has_many :tags, through: :job_tags
  has_many :applications, dependent: :destroy
  has_many :saved_jobs, dependent: :destroy

  # Configure natural language search
  pg_search_scope :search_jobs,
    against: {
      title: "A",
      description: "B",
      location: "C"
    },
    associated_against: {
      company: [ :name, :industry ]
    },
    using: {
      tsearch: {
        prefix: true,
        dictionary: "english"
      },
      trigram: {
        threshold: 0.3
      }
    }

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

  def to_param
    id
  end

  def remote_friendly?
    return false if location.blank?

    remote_keywords = [ "remote", "worldwide", "anywhere", "distributed", "home" ]
    location.downcase.split.any? { |word| remote_keywords.include?(word) }
  end

  def has_salary?
    salary_min.present? || salary_max.present?
  end

  def salary_range_display
    return "Not specified" unless has_salary?

    min_str = salary_min.present? ? number_with_delimiter(salary_min) : "0"
    max_str = salary_max.present? ? number_with_delimiter(salary_max) : "Open"

    if salary_min.present? && salary_max.present?
      "#{currency} #{min_str} - #{max_str}"
    elsif salary_min.present?
      "#{currency} #{min_str}+"
    elsif salary_max.present?
      "Up to #{currency} #{max_str}"
    end
  end

  def days_since_posted
    return 0 unless posted_at.present?

    (Time.current.to_date - posted_at.to_date).to_i
  end

  def fresh?
    days_since_posted <= 7
  end

  def expired?
    return false unless posted_at.present?

    days_since_posted > 90
  end

  def external_job?
    source != "internal"
  end

  def company_name
    company&.name
  end

  def company_logo
    company&.logo_url
  end

  private

  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
