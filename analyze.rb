#!/usr/bin/env ruby

#usage: analyze.rb REDIS_PORT
#produces CSV with stats by key pattern

require 'rubygems'
require 'redis'

REDIS_PORT = (ARGV[0] || 6380).to_i
$redis = Redis.new port: REDIS_PORT

STDERR.puts "reading all keys and finding out patterns..."

#find out patterns -------------------------------------------------------
patterns = Hash.new(0)
$redis.keys('*').each do |key|
  #assume "components" that start with numbers are IDs and can be folded
  components = key.split(':').map{|c| c.match(/^\d/) ? 'ID' : c}
  pattern = components.join(':')
  patterns[pattern] += 1
end

STDERR.puts "discovered #{patterns.count} patterns over #{patterns.values.reduce(:+)} keys"
STDERR.puts ""

#find out stats for each pattern -----------------------------------------
sizes = {}
types = {}
patterns.each do |p, c|
  STDERR.puts "analyzing #{p} with #{c} keys..."

  keys_pattern = p.split(':').map{|c| c == 'ID' ? '*' : c}.join(':')
  keys = $redis.keys keys_pattern
  sample_key = keys[0]

  type = $redis.type sample_key
  debugs = $redis.pipelined do
    keys.map do |key|
      $redis.debug 'object', key
    end
  end
  regex = /serializedlength:(\d+)/
  size = debugs.map{|d| d.scan(regex)[0][0].to_i }.reduce(:+)

  sizes[p] = size
  types[p] = type
end

#print out CSV -----------------------------------------------------------
STDERR.puts ""
puts "pattern,type,count,size"
patterns.sort_by{|p, c| -c}.each do |p, c|
  type = types[p]
  size = sizes[p]
  puts "#{p},#{type},#{c},#{size}"
end
