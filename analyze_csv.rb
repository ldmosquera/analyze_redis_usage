#!/usr/bin/env ruby

require 'rubygems'
require 'redis'

#usage: cat rdb_tools_csv_output.csv | analyze_csv.rb
#produces CSV with stats by key pattern
#ex: [foo:bar:123, foo:bar:234] -> foo:bar:ID

first = true
patterns = Hash.new(0)
size_by_pattern = Hash.new(0)
type_by_pattern = {}
id_regex = /^\d/

key_count = 0

STDIN.each_line do |line|
  #skip first (headers)
  if first
    first = false
    next
  end

  type, key, size = line.split(',')[1 .. 3]

  pattern = key.split(':').map{|count| count.match(id_regex) ? 'ID' : count}.join(':')

  patterns[pattern] += 1
  size_by_pattern[pattern] += size.to_i
  type_by_pattern[pattern] ||= type

  key_count += 1
end

STDERR.puts "discovered #{patterns.count} patterns over #{key_count} keys"
STDERR.puts ""

#print out CSV -----------------------------------------------------------
STDERR.puts ""
puts "pattern,type,count,size"
patterns.sort_by{|pat, count| -count}.each do |pat, count|
  type = type_by_pattern[pat]
  size = size_by_pattern[pat]
  puts "#{pat},#{type},#{count},#{size}"
end

