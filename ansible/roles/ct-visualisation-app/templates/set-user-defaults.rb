#!/usr/bin/env ruby

def update_user(login, user_data)
  puts "Updating #{login} user"
  user = Uma::User.where(login: login).order(:created_at => 'asc').first
  if user.nil?
    puts "    -> user not found"
  else
    puts "    -> found user: #{user.id}"
    password = user_data["password"]
    email = user_data["email"]
    user.password = password
    user.password_confirmation = password
    user.email = email
    # The password might be too short to pass validation.  We assume that we
    # know what we're doing with such passwords.
    user.save!(validate: false)
  end
end

user_data = YAML.load_file("{{ct_etc_dir}}/default-user-data.yml")
user_data.each do |login, data|
  update_user(login, data)
end
