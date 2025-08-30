class UserProfile < ApplicationRecord
  belongs_to :user
  has_many :applications, foreign_key: :resume_id

  # Active Storage attachments
  has_one_attached :resume
  has_one_attached :profile_picture
  has_many_attached :portfolio_files
  has_many_attached :certificates

  # Custom validations for Active Storage attachments
  validate :resume_format, if: -> { resume.attached? }
  validate :resume_size, if: -> { resume.attached? }
  validate :profile_picture_format, if: -> { profile_picture.attached? }
  validate :profile_picture_size, if: -> { profile_picture.attached? }
  validate :portfolio_files_format, if: -> { portfolio_files.attached? }
  validate :portfolio_files_size, if: -> { portfolio_files.attached? }
  validate :certificates_format, if: -> { certificates.attached? }
  validate :certificates_size, if: -> { certificates.attached? }

  # Helper methods
  def resume_attached?
    resume.attached?
  end

  def profile_picture_attached?
    profile_picture.attached?
  end

  def has_portfolio_files?
    portfolio_files.attached?
  end

  def has_certificates?
    certificates.attached?
  end

  private

  def resume_format
    return unless resume.attached?

    acceptable_types = [ "application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ]
    unless acceptable_types.include?(resume.content_type)
      errors.add(:resume, "must be a PDF or Word document")
    end
  end

  def resume_size
    return unless resume.attached?

    if resume.byte_size > 5.megabytes
      errors.add(:resume, "must be less than 5MB")
    end
  end

  def profile_picture_format
    return unless profile_picture.attached?

    acceptable_types = [ "image/png", "image/jpg", "image/jpeg" ]
    unless acceptable_types.include?(profile_picture.content_type)
      errors.add(:profile_picture, "must be a PNG or JPEG image")
    end
  end

  def profile_picture_size
    return unless profile_picture.attached?

    if profile_picture.byte_size > 2.megabytes
      errors.add(:profile_picture, "must be less than 2MB")
    end
  end

  def portfolio_files_format
    return unless portfolio_files.attached?

    acceptable_types = [ "application/pdf", "image/png", "image/jpg", "image/jpeg" ]
    portfolio_files.each do |file|
      unless acceptable_types.include?(file.content_type)
        errors.add(:portfolio_files, "must be PDF or image files")
        break
      end
    end
  end

  def portfolio_files_size
    return unless portfolio_files.attached?

    portfolio_files.each do |file|
      if file.byte_size > 10.megabytes
        errors.add(:portfolio_files, "each file must be less than 10MB")
        break
      end
    end
  end

  def certificates_format
    return unless certificates.attached?

    acceptable_types = [ "application/pdf", "image/png", "image/jpg", "image/jpeg" ]
    certificates.each do |file|
      unless acceptable_types.include?(file.content_type)
        errors.add(:certificates, "must be PDF or image files")
        break
      end
    end
  end

  def certificates_size
    return unless certificates.attached?

    certificates.each do |file|
      if file.byte_size > 5.megabytes
        errors.add(:certificates, "each file must be less than 5MB")
        break
      end
    end
  end
end
