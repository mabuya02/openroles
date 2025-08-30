class ApplicationStatus
  APPLIED = "applied"
  UNDER_REVIEW = "under_review"
  INTERVIEW = "interview"
  REJECTED = "rejected"
  HIRED = "hired"

  VALUES = [ APPLIED, UNDER_REVIEW, INTERVIEW, REJECTED, HIRED ].freeze

  # Class method for easier access
  def self.values
    VALUES
  end

  # Optional: human readable labels
  LABELS = {
    APPLIED => "Applied",
    UNDER_REVIEW => "Under Review",
    INTERVIEW => "Interview",
    REJECTED => "Rejected",
    HIRED => "Hired"
  }.freeze
end
