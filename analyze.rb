#!/usr/bin/env ruby

require 'rubygems'
require 'redis'

#usage: cat patterns | analyze.rb REDIS_PORT
#produces CSV with stats by key pattern
#ex: [foo:bar:123, foo:bar:234] -> foo:bar:ID

patterns = []
STDIN.each_line do |line|
  patterns << line.strip.split(',')[0..1]
end

#find out stats for each pattern -----------------------------------------
sizes = {}
types = {}
debug_object_regex = /serializedlength:(\d+)/
patterns.each do |p, c|
  STDERR.puts "analyzing #{p} with #{c} keys..."

  keys = keys_by_pattern.delete p
  type = $redis.type keys[0]

  debugs = $redis.pipelined do
    keys.map do |key|
      $redis.debug 'object', key
    end
  end
  size = debugs.map{|d| d.scan(debug_object_regex)[0][0].to_i }.reduce(:+)

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
