#!/usr/bin/env ruby1.9

require 'yaml'
    
personality = YAML.load_file("/etc/concurrent-thinking/appliance/personality.yml")
    
manufacturer = personality[:manufacturer] || 'Concertim Infrastructure Management'
mia_name = personality[:mia_chassis_template_name] || personality[:title] || 'Command'
isla_name = personality[:isla_chassis_template_name] || personality[:title] || 'Control'

%w( mia isla ).each do |appliance|
  File.open("/data/private/share/rails/hacor/app/models/chassis_templates/#{appliance}.yaml.tagged", "r") do |template|
    File.open("/data/private/share/rails/hacor/app/models/chassis_templates/#{appliance}.yaml", "w") do |f|
      s = template.read
      s.gsub!('%MANUFACTURER%', manufacturer)
      s.gsub!('%MIA_CHASSIS_TEMPLATE_NAME%', mia_name)
      s.gsub!('%ISLA_CHASSIS_TEMPLATE_NAME%', isla_name)
      f.write(s)
    end
  end
end
