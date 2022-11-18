#!/usr/bin/env ruby

require 'rubygems'
require 'memcache'

m=MemCache.new('localhost:11211')
configs = m.get('hacor:appliance_configs') || {}

arrays = {
  :sub_groups => ['Sub groups','hacor:group:'],
  :strict_sub_groups => ['Strict sub groups','hacor:group:'],
  :dup_groups => ['Duplicate groups','hacor:group:'],
  :racks => ['Racks','hacor:rack:'],
}

hashes = {
  :user_metrics => ['User metrics','meca:inferred_metric:']
}

configs.each do |eui, config|
  puts "--- #{eui} ---"
  puts "Device: #{(config[:device]||'').match(/hacor:device:(.*)/)[1]}"
  puts "Group: #{(config[:group]||'').match(/hacor:group:(.*)/)[1]}"
  arrays.each do |key, info|
    puts "#{info[0]}: #{config[key].collect{|g| g.match(/#{info[1]}(.*)/)[1] rescue ''}.join(', ')}"
  end
  hashes.each do |key, info|
    config[key].each { |entry, info| puts "#{entry.match(/#{info[1]}(.*)/)[1]} #{info.inspect}" }
  end
end
