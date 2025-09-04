class Alert < ApplicationRecord
  belongs_to :user
  has_many :alerts_tags, dependent: :destroy
  has_many :tags, through: :alerts_tags

  validates :status, inclusion: { in: AlertStatus::VALUES }
  validates :criteria, presence: true
  validates :frequency, inclusion: { in: %w[daily weekly monthly] }
  validates :unsubscribe_token, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_unsubscribe_token, if: -> { unsubscribe_token.blank? }

  # Scopes
  scope :active, -> { where(status: AlertStatus::ACTIVE) }
  scope :ready_for_notification, ->(frequency) {
    where(frequency: frequency, status: AlertStatus::ACTIVE)
      .where("last_notified_at IS NULL OR last_notified_at < ?", notification_threshold(frequency))
  }

  # Class method to determine notification threshold based on frequency
  def self.notification_threshold(frequency)
    case frequency
    when "daily"
      1.day.ago
    when "weekly"
      1.week.ago
    when "monthly"
      1.month.ago
    else
      1.day.ago
    end
  end

  # Instance methods
  def should_notify?
    return false unless active?
    return true if last_notified_at.blank?

    last_notified_at < self.class.notification_threshold(frequency)
  end

  def mark_as_notified!
    update!(last_notified_at: Time.current)
  end

  def matching_jobs
    query = Job.joins(:company).published

    # Apply criteria filters from JSON
    if criteria.present?
      # Handle natural language query or keywords
      search_terms = nil
      if criteria["natural_query"].present?
        search_terms = criteria["natural_query"]
      elsif criteria["keywords"].present?
        search_terms = criteria["keywords"]
      end

      # Search in title, description, and company name
      if search_terms.present?
        search_terms = search_terms.to_s.downcase
        # Split search terms and search for any of them
        terms = search_terms.split(/[\s,]+/).reject(&:blank?)

        if terms.any?
          term_conditions = []
          term_params = []

          terms.each do |term|
            term_conditions << "(jobs.title ILIKE ? OR jobs.description ILIKE ? OR companies.name ILIKE ?)"
            term_params += [ "%#{term}%", "%#{term}%", "%#{term}%" ]
          end

          query = query.where(term_conditions.join(" OR "), *term_params)
        end
      end

      # Location filter
      if criteria["location"].present?
        query = query.where("jobs.location ILIKE ?", "%#{criteria['location']}%")
      end

      # Employment type filter
      if criteria["employment_type"].present?
        query = query.where(employment_type: criteria["employment_type"])
      end

      # Salary range filter
      if criteria["salary_min"].present?
        query = query.where("salary_min >= ? OR salary_max >= ?", criteria["salary_min"], criteria["salary_min"])
      end

      if criteria["salary_max"].present?
        query = query.where("salary_min <= ? OR salary_max <= ?", criteria["salary_max"], criteria["salary_max"])
      end
    end

    # Apply tag filters if tags are present
    if tags.any?
      tag_ids = tags.pluck(:id)
      query = query.joins(:tags).where(tags: { id: tag_ids })
    end

    # Only return jobs posted after the last notification or alert creation
    cutoff_time = last_notified_at || created_at
    query.where("jobs.posted_at > ? OR jobs.created_at > ?", cutoff_time, cutoff_time)
  end

  def active?
    status == AlertStatus::ACTIVE
  end

  def unsubscribe!
    update!(status: AlertStatus::INACTIVE)
  end

  def reactivate!
    update!(status: AlertStatus::ACTIVE, last_notified_at: nil)
  end

  private

  def generate_unsubscribe_token
    self.unsubscribe_token = SecureRandom.urlsafe_base64(32)
  end
end
