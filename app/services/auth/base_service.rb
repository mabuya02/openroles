# frozen_string_literal: true

module Auth
  # Base service class for authentication-related services
  # Provides common structure and methods for error handling
  class BaseService
    attr_reader :errors, :user

    def initialize
      @errors = []
      @user = nil
    end

    # Check if the service operation was successful
    # @return [Boolean] true if no errors occurred
    def success?
      @errors.empty?
    end

    # Add an error message
    # @param message [String] Error message to add
    def add_error(message)
      @errors << message
    end

    # Add multiple error messages
    # @param messages [Array<String>] Error messages to add
    def add_errors(messages)
      @errors.concat(messages)
    end

    # Check if email format is valid
    # @param email [String] Email to validate
    # @return [Boolean] true if email format is valid
    def valid_email_format?(email)
      return false if email.blank?
      email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    end

    # Validate password strength
    # @param password [String] Password to validate
    # @param min_length [Integer] Minimum password length
    # @return [Boolean] true if password meets requirements
    def valid_password?(password, min_length: 8)
      if password.blank?
        add_error("Password is required")
        return false
      end

      if password.length < min_length
        add_error("Password must be at least #{min_length} characters long")
        return false
      end

      true
    end

    # Validate password confirmation matches
    # @param password [String] Password
    # @param confirmation [String] Password confirmation
    # @return [Boolean] true if passwords match
    def passwords_match?(password, confirmation)
      if password != confirmation
        add_error("Password confirmation doesn't match password")
        return false
      end

      true
    end
  end
end
