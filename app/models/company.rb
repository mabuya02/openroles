class Company < ApplicationRecord
  has_many :jobs, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: CompanyStatus::VALUES }
end
