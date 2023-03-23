#!/usr/bin/env ruby1.9

def update_user(login, user_data)
  puts "Updating #{login} user"
  user = Uma::User.where(login: login).order(:created_at => 'asc').first
  if user.nil?
    puts "    -> user not found"
  else
    puts "    -> found user: #{user.id}"
    password = user_data["#{login}_password"]
    email = user_data["#{login}_email"]
    user.password = password
    user.password_confirmation = password
    user.email = email
    # The password might be too short to pass validation.  We assume that we
    # know what we're doing with such passwords.
    user.save!(validate: false)
  end
end

user_data = YAML.load_file("/data/private/share/etc/concurrent-thinking/appliance/default-user-data.yml")

update_user('admin', user_data)
update_user('operator', user_data)
