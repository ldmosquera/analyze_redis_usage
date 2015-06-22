#!/usr/bin/env ruby

#usage: analyze.rb REDIS_PORT
#produces CSV with stats by key pattern
#ex: [foo:bar:123, foo:bar:234] -> foo:bar:ID

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
