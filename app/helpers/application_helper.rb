module ApplicationHelper
  # Include Pagy helpers for pagination views
  include Pagy::Frontend

  # Create alert flash messages with custom options
  def flash_alert(message, type = :info, options = {})
    duration = options[:duration] || 4000
    auto_hide = options[:auto_hide] != false
    fixed = options[:fixed] || false

    flash[type] = message

    # Store options for the alert controller
    session[:alert_options] = {
      duration: duration,
      auto_hide: auto_hide,
      fixed: fixed
    }
  end

  # Quick helper methods for different alert types
  def flash_success(message, options = {})
    flash_alert(message, :success, options)
  end

  def flash_error(message, options = {})
    flash_alert(message, :error, options)
  end

  def flash_warning(message, options = {})
    flash_alert(message, :warning, options)
  end

  def flash_info(message, options = {})
    flash_alert(message, :info, options)
  end

  # Create persistent alerts that don't auto-hide
  def flash_persistent(message, type = :info)
    flash_alert(message, type, auto_hide: false)
  end

  # Create important alerts that are fixed positioned
  def flash_important(message, type = :warning)
    flash_alert(message, type, fixed: true, duration: 8000)
  end
end
