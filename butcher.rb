#!/usr/bin/env ruby

#WARNING: DESTRUCTIVE!!!!!!!!!
#WARNING: DESTRUCTIVE!!!!!!!!!
#WARNING: DESTRUCTIVE!!!!!!!!!

#reads in a list of patterns then for each one, REMOVES ALL KEYS FOR THAT PATTERN
#then reports Redis RSS usage afterwards, thus giving an idea of the real RSS cost of each pattern.

require 'redis'

HOST = ENV['HOST'] || 'localhost'
PORT = (ENV['PORT'] || '6380').to_i
R = Redis.new host: HOST, port: PORT

patterns = STDIN.readlines.map{|l| l.strip.split(',').first.gsub(/:ID/, ':*') }

def get_size
  R.info['used_memory_rss']
end

def fucking_delete_this_shit(slice)
  while true
    R.del slice
    return
  end
  rescue
    retry
end

def delete_pattern(pat)
  R.keys(pat).each_slice(1000) do |slice|
    fucking_delete_this_shit slice
  end
end

puts "initial,#{get_size}"

patterns.each do |pat|
  printf "#{pat},"
  delete_pattern pat
  sleep 10

  size_now = get_size
  puts "#{get_size}"
end

