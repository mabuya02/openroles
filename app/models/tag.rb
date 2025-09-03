class Tag < ApplicationRecord
  has_many :job_tags, dependent: :destroy
  has_many :jobs, through: :job_tags
  has_many :alerts_tags, dependent: :destroy
  has_many :alerts, through: :alerts_tags

  validates :name, presence: true, uniqueness: true

  # New attributes for job fetching strategy
  # We can add these via migration later, but for now we'll use conventions

  # Scopes
  scope :popular, -> { joins(:jobs).group("tags.id").having("COUNT(jobs.id) > ?", 5) }
  scope :for_alerts, -> { joins(:alerts).distinct }
  scope :active_for_fetching, -> { where("name IS NOT NULL AND LENGTH(name) > 0") }
  scope :by_job_count, -> { left_joins(:jobs).group("tags.id").order("COUNT(jobs.id) DESC") }

  # Job fetching related scopes
  scope :technology_tags, -> { where("LOWER(name) SIMILAR TO '%(dev|program|engineer|tech|software|web|mobile|data|ai|ml|cloud|cyber)%'") }
  scope :industry_tags, -> { where("LOWER(name) SIMILAR TO '%(finance|health|education|market|sales|design|hr|legal|consult)%'") }
  scope :skill_tags, -> { where("LOWER(name) SIMILAR TO '%(react|python|java|ruby|node|sql|aws|docker|git)%'") }
  scope :level_tags, -> { where("LOWER(name) SIMILAR TO '%(senior|junior|lead|manager|director|entry|intern)%'") }

  # Normalize tag name before saving
  before_validation :normalize_name

  def to_param
    name.parameterize
  end

  # Class methods for job fetching
  def self.get_fetching_keywords(strategy: :balanced, limit: 20)
    case strategy.to_sym
    when :popular
      # Use tags that already have jobs (proven to work)
      by_job_count.limit(limit).pluck(:name)
    when :diverse
      # Mix of different types of tags
      tech_tags = technology_tags.limit(limit / 4).pluck(:name)
      industry_tags = self.industry_tags.limit(limit / 4).pluck(:name)
      skill_tags = self.skill_tags.limit(limit / 4).pluck(:name)
      level_tags = self.level_tags.limit(limit / 4).pluck(:name)
      (tech_tags + industry_tags + skill_tags + level_tags).compact
    when :technology_focused
      technology_tags.limit(limit).pluck(:name)
    when :broad
      # All available tags
      active_for_fetching.limit(limit).pluck(:name)
    else
      # Balanced approach - mix of popular and diverse
      popular_tags = by_job_count.limit(limit / 2).pluck(:name)
      diverse_tags = active_for_fetching.where.not(id: by_job_count.limit(limit / 2).select(:id)).limit(limit / 2).pluck(:name)
      popular_tags + diverse_tags
    end
  end

  def self.create_industry_seed_data
    # Create comprehensive tag seed data if the database is empty
    existing_count = Tag.count
    return { created: 0, existing: existing_count } if existing_count > 50

    industry_keywords = [
      # Technology & Development
      "software engineer", "full stack developer", "frontend developer", "backend developer",
      "mobile developer", "web developer", "devops engineer", "data scientist", "machine learning",
      "artificial intelligence", "cybersecurity", "cloud engineer", "react", "nodejs", "python",
      "java", "javascript", "ruby on rails", "angular", "vue", "docker", "kubernetes", "aws",

      # Business & Management
      "project manager", "product manager", "business analyst", "operations manager",
      "account manager", "team lead", "director", "executive", "consultant", "coordinator",

      # Marketing & Sales
      "digital marketing", "marketing manager", "content marketing", "social media", "seo",
      "sales manager", "account executive", "business development", "growth marketing",
      "email marketing", "ppc", "affiliate marketing",

      # Design & Creative
      "ui designer", "ux designer", "graphic designer", "web designer", "product designer",
      "visual designer", "brand designer", "creative director", "illustrator", "photographer",

      # Finance & Accounting
      "accountant", "financial analyst", "bookkeeper", "controller", "cfo", "financial planner",
      "investment analyst", "risk analyst", "auditor", "tax specialist", "budget analyst",

      # Healthcare & Medical
      "nurse", "doctor", "physician", "medical assistant", "therapist", "pharmacist",
      "healthcare administrator", "medical technician", "telemedicine", "medical coding",

      # Human Resources
      "hr manager", "recruiter", "talent acquisition", "hr specialist", "hr generalist",
      "compensation analyst", "training coordinator", "employee relations",

      # Customer Service & Support
      "customer service", "customer support", "technical support", "help desk",
      "customer success", "call center", "chat support",

      # Education & Training
      "teacher", "instructor", "professor", "tutor", "educational coordinator",
      "curriculum developer", "training specialist", "academic advisor",

      # Legal & Compliance
      "lawyer", "attorney", "legal counsel", "paralegal", "compliance officer",
      "contract specialist", "legal analyst",

      # Remote Work & Flexibility
      "remote", "work from home", "telecommute", "distributed", "virtual", "flexible",
      "location independent", "anywhere", "hybrid",

      # Experience Levels
      "entry level", "junior", "mid level", "senior", "lead", "principal", "staff",
      "manager", "director", "vp", "c-level", "executive", "intern", "graduate"
    ]

    created_count = 0
    industry_keywords.each do |keyword|
      tag = Tag.find_or_create_by(name: keyword.downcase)
      created_count += 1 if tag.previously_new_record?
    end

    Rails.logger.info "Created #{created_count} new industry tags for job fetching"

    {
      created: created_count,
      existing: existing_count,
      total: Tag.count
    }
  end

  private

  def normalize_name
    self.name = name.strip.downcase if name.present?
  end
end
