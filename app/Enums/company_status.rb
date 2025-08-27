class CompanyStatus
  ACTIVE = "active"
  INACTIVE = "inactive"
  SUSPENDED = "suspended"

  # List of all values
  VALUES = [ ACTIVE, INACTIVE, SUSPENDED ].freeze

  # Class method for easier access
  def self.values
    VALUES
  end

  # Optional: human readable labels
  LABELS = {
    ACTIVE => "Active",
    INACTIVE => "Inactive",
    SUSPENDED => "Suspended"
  }.freeze
end
