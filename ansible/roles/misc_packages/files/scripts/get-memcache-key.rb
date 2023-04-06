#!/usr/bin/env ruby

require 'dalli'
require 'dalli/client'
require 'json'

address = "localhost:11211"
mc = Dalli::Client.new(address, { serializer: Marshal })
puts mc.get(ARGV[0]).to_json
