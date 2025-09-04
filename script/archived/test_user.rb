puts "Testing user creation with default password directly..."

begin
  default_password = "OpenRoles2025!"

  user = User.new(
    email: "test2@example.com",
    password: default_password,
    first_name: "Test",
    last_name: "User",
    phone_number: "+254758316403",
    email_verified: false,
    two_factor_enabled: false
  )

  puts "User attributes:"
  puts "- Email: " + user.email.to_s
  puts "- Password present?: " + user.password_digest.present?.to_s
  puts "- Valid?: " + user.valid?.to_s

  if user.valid?
    puts "✅ User is valid, saving..."
    user.save!
    puts "User saved with ID: " + user.id.to_s
    puts "Can authenticate?: " + user.authenticate(default_password).to_s
  else
    puts "❌ User validation errors:"
    user.errors.each { |error| puts "  - " + error.full_message }
  end

rescue => e
  puts "❌ Exception: " + e.message
  puts "Backtrace: " + e.backtrace.first(3).join("; ")
end
