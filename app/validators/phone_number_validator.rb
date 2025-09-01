class PhoneNumberValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_blank]

    unless valid_phone_number?(value)
      record.errors.add(attribute, options[:message] || "Invalid phone number format")
    end
  end

  private

  def valid_phone_number?(phone_number)
    return false if phone_number.blank?

    parsed_phone = Phonelib.parse(phone_number)
    parsed_phone.possible?
  end
end
