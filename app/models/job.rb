class Job < ApplicationRecord
  belongs_to :company
  has_one :job_metadata, dependent: :destroy
  has_many :job_tags, dependent: :destroy
  has_many :tags, through: :job_tags
  has_many :applications, dependent: :destroy
  has_many :saved_jobs, dependent: :destroy

  validates :status, inclusion: { in: JobStatus::VALUES }
  validates :employment_type, inclusion: { in: EmploymentType::VALUES }
end
