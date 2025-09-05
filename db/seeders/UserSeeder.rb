class UserSeeder
  def self.seed
    puts "Seeding Users..."

    users_data = [
      {
        first_name: "Mabuya",
        last_name: "Maina",
        email: "mainamanasseh02@gmail.com",
        phone_number: "+254758316403",
        password: "Mabuya02.dev1",
        status: UserStatus::ACTIVE,
        email_verified: true
      },
      {
        first_name: "Joshua",
        last_name: "Mwangi",
        email: "mwangijoshua990@gmail.com",
        phone_number: "+254702798550",
        password: "Mabuya02.dev!",
        status: UserStatus::ACTIVE,
        email_verified: true
      }
    ]

    users_data.each do |u|
      user = User.create!(
        first_name: u[:first_name],
        last_name: u[:last_name],
        email: u[:email],
        phone_number: u[:phone_number],
        password: u[:password],
        status: u[:status],
        email_verified: u[:email_verified]
      )
      puts "Created user: #{user.email}"
    end

    puts "User seeding complete!"
  end
end
