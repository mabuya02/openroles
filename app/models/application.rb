class Application < ApplicationRecord
  belongs_to :user
  belongs_to :job
  belongs_to :resume, class_name: "UserProfile", optional: true

  # Active Storage attachments
  has_one_attached :cover_letter_file
  has_many_attached :additional_documents

  # Validations
  validates :status, inclusion: { in: ApplicationStatus::VALUES }

  # Custom validations for Active Storage attachments
  validate :cover_letter_format, if: -> { cover_letter_file.attached? }
  validate :cover_letter_size, if: -> { cover_letter_file.attached? }
  validate :additional_documents_format, if: -> { additional_documents.attached? }
  validate :additional_documents_size, if: -> { additional_documents.attached? }

  # Scopes
  scope :with_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }

  # Helper methods
  def cover_letter_attached?
    cover_letter_file.attached?
  end

  def has_additional_documents?
    additional_documents.attached?
  end

  def resume_from_profile
    resume&.resume if resume&.resume&.attached?
  end

  def status_label
    ApplicationStatus::LABELS[status] || status.humanize
  end

  private

  def cover_letter_format
    return unless cover_letter_file.attached?

    acceptable_types = [ "application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ]
    unless acceptable_types.include?(cover_letter_file.content_type)
      errors.add(:cover_letter_file, "must be a PDF or Word document")
    end
  end

  def cover_letter_size
    return unless cover_letter_file.attached?

    if cover_letter_file.byte_size > 5.megabytes
      errors.add(:cover_letter_file, "must be less than 5MB")
    end
  end

  def additional_documents_format
    return unless additional_documents.attached?

    acceptable_types = [ "application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "image/png", "image/jpg", "image/jpeg" ]
    additional_documents.each do |file|
      unless acceptable_types.include?(file.content_type)
        errors.add(:additional_documents, "must be PDF, Word, or image files")
        break
      end
    end
  end

  def additional_documents_size
    return unless additional_documents.attached?

    additional_documents.each do |file|
      if file.byte_size > 10.megabytes
        errors.add(:additional_documents, "each file must be less than 10MB")
        break
      end
    end
  end
end
