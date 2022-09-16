#!/usr/bin/env ruby1.9

security = YAML.load_file("/usr/src/concurrent-thinking/security.yml")
setup_data = YAML.load_file("/usr/src/concurrent-thinking/setup-data.yml")

puts "Updating integrator user"
integrator = User.find_first_by_authorisation('Integrator', :created_on => 'asc')
if integrator.nil?
  puts "    -> integrator not found"
else
  puts "    -> found user: #{integrator.login}"
  puts "    -> updating integrator with password: #{security['integrator_password']}"
  integrator.password = security['integrator_password']
  integrator.password_confirmation = security['integrator_password']
  integrator.root = true
  integrator.save!
end


puts "Updating operator user"
operator = User.find_first_by_authorisation('Operator', :created_on => 'asc')
if operator.nil?
  puts "    -> operator not found"
else
  password = 'operator'
  puts "    -> found user: #{operator.login}"
  puts "    -> updating operator with password: #{password}"
  operator.password = password
  operator.password_confirmation = password
  operator.email = "operator@test.com" if operator.email.blank?
  operator.save!
end

puts "Updating admin user"
admin = User.find_first_by_authorisation('Administrator', :created_on => 'asc')
if admin.nil?
  puts "    -> admin not found"
else
  password = setup_data["admin_data"] && setup_data["admin_data"]["password"] || "admin"
  puts "    -> found user: #{admin.login}"
  puts "    -> updating admin with password: #{password}"
  admin.password = password
  admin.password_confirmation = password
  admin.root = true
  admin.save!
end
