#!/usr/bin/env ruby1.9

user_data = YAML.load_file("/data/private/share/etc/concurrent-thinking/appliance/ftsw-user-data.yml")

puts "Updating integrator user"
integrator = Uma::User.where(authorisation: 'Integrator').order(:created_on => 'asc').first
if integrator.nil?
  puts "    -> integrator not found"
else
  password = user_data['integrator_password']
  puts "    -> found user: #{integrator.login}"
  puts "    -> updating integrator with password: #{password}"
  integrator.password = password
  integrator.password_confirmation = password
  integrator.email = user_data['integrator_email'] if integrator.email.blank?
  integrator.root = true
  integrator.save!
end


puts "Updating operator user"
operator = Uma::User.where(authorisation: 'Operator').order(:created_on => 'asc').first
if operator.nil?
  puts "    -> operator not found"
else
  password = user_data['operator_password']
  puts "    -> found user: #{operator.login}"
  puts "    -> updating operator with password: #{password}"
  operator.password = password
  operator.password_confirmation = password
  operator.email = user_data['operator_password'] if operator.email.blank?
  operator.save!
end

puts "Updating admin user"
admin = Uma::User.where(authorisation: 'Administrator').order(:created_on => 'asc').first
if admin.nil?
  puts "    -> admin not found"
else
  password = user_data['admin_password']
  puts "    -> found user: #{admin.login}"
  puts "    -> updating admin with password: #{password}"
  admin.password = password
  admin.password_confirmation = password
  admin.email = user_data['admin_email'] if admin.email.blank?
  admin.root = true
  # The password is too short to pass validation.
  admin.save!(validate: false)
end
