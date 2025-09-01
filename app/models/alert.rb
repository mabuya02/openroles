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
    query = Job.published

    # Apply tag filters if tags are present
    if tags.any?
      tag_ids = tags.pluck(:id)
      query = query.joins(:tags).where(tags: { id: tag_ids })
    end

    # Apply criteria filters from JSON
    if criteria.present?
      # Location filter
      if criteria["location"].present?
        query = query.where("location ILIKE ?", "%#{criteria['location']}%")
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

      # Keywords search
      if criteria["keywords"].present?
        query = query.search(criteria["keywords"])
      end
    end

    # Only return jobs posted after the last notification or alert creation
    cutoff_time = last_notified_at || created_at
    query.where("jobs.posted_at > ?", cutoff_time)
  end

  private

  def generate_unsubscribe_token
    self.unsubscribe_token = SecureRandom.urlsafe_base64(32)
  end

  def active?
    status == AlertStatus::ACTIVE
  end
end
