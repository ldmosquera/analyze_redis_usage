#!/usr/bin/env ruby

#usage: get_patterns.rb REDIS_PORT
#produces CSV with representative key patterns

require 'rubygems'
require 'redis'

REDIS_PORT = (ARGV[0] || 6379).to_i
$redis = Redis.new port: REDIS_PORT

STDERR.puts "reading all keys and finding out patterns..."

#find out patterns -------------------------------------------------------
patterns = Hash.new(0)
keys_by_pattern = Hash.new{|hash,key| hash[key] = []}
id_regex = /^\d/

begin
  cursor, keys = $redis.scan(cursor, match: '*', count: 500000)
  keys.each do |key|
    #assume "components" that start with numbers are IDs and can be summarized
    pattern = key.split(':').map{|c| c.match(id_regex) ? 'ID' : c}.join(':')
    patterns[pattern] += 1
    #keys_by_pattern[pattern] << key
  end
end while cursor.to_i != 0

STDERR.puts "discovered #{patterns.count} patterns over #{patterns.values.reduce(:+)} keys"
STDERR.puts ""

patterns.each do |p, count|
  puts [p, count].join(',')
end

