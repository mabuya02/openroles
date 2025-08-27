class UserStatus
  ACTIVE = "activated"
  INACTIVE = "inactive"
  SUSPENDED = "suspended"
  LOCKED = "locked"

  # List of all values
  VALUES = [ ACTIVE, INACTIVE, SUSPENDED, LOCKED ].freeze

  # Class method for easier access
  def self.values
    VALUES
  end

  # Optional: human readable labels
  LABELS = {
    ACTIVE => "Active",
    INACTIVE => "Inactive",
    SUSPENDED => "Suspended",
    LOCKED => "Locked"
  }.freeze
end
