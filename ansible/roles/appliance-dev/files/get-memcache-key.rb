#!/usr/bin/env ruby1.9

require 'memcache'
require 'json'

mc = MemCache.new('127.0.0.1:11211')
puts mc.get(ARGV[0]).to_json
