# analyze_redis_usage

Redneck tools to analyze Redis space usage

## get_patterns.rb

Iterates over keys in a running Redis instance and prints out patterns plus key counts in CSV format

## analyze.rb

Reads in get_patterns.rb CSV and finds out space usage based on serialized size

## bucher.rb

**WARNING - DESTRUCTIVE** - use it only on backup copies, preferably read-only

Reads in get_patterns.rb CSV and brutishly finds out REAL runtime space usage by deleting each pattern then querying Redis RSS usage afterwards.
