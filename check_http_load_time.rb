#!/usr/bin/env ruby

require 'json'
require 'uri'
require 'time'
require 'optparse'

options = {}
options[:phantomjs] = "/usr/bin/phantomjs --load-images=yes --load-plugins=yes --local-to-remote-url-access=yes --disk-cache=no"
options[:snifferjs] = "netsniff.js"
options[:display]   = ":1"
options[:warning]   = 1.0
options[:critical]  = 2.0

OptionParser.new do |opts|
	opts.banner = "Usage: {$0} [options]"

	opts.on("-s", "--sniffer [STRING]", "path to phantomjs netsniff" ) do |s|
		options[:snifferjs] = s
	end
	opts.on("-d", "--display [STRING]", "display for PhantomJS" ) do |d|
		options[:display] = d
	end
	opts.on("-u", "--url [STRING]", "URL to query" ) do |u|
		options[:url] = u
	end
	opts.on("-w", "--warning [FLOAT]", "Time when warning") do |w|
		options[:warning] = w
	end
	opts.on("-c", "--critical [FLOAT]", "Time when critical") do |c|
		options[:critical] = c
	end
end.parse!

website_url = URI(options[:url])
website_load_time = 0.0

# Run Phantom
output = IO.popen("env DISPLAY=" + options[:display] + " " + options[:phantomjs] + " " + options[:snifferjs] + " " + website_url.to_s + " 2> /dev/null" )

json = output.readlines
begin
	hash = JSON.parse(json.join)
rescue
	puts "Unkown: Could not parse JSON from phantomjs"
	exit 3
end

request_global_time_start = Time.iso8601(hash['log']['pages'][0]['startedDateTime'])
request_global_time_end   = Time.iso8601(hash['log']['pages'][0]['endedDateTime'])

website_load_time = '%.2f' % (request_global_time_end - request_global_time_start)

performance_data = " | load_time=#{website_load_time.to_s}"

if website_load_time.to_f > options[:critical].to_f
	puts "Critical: #{website_url.to_s} load time: #{website_load_time.to_s}" + performance_data
	exit 2
elsif website_load_time.to_f > options[:warning].to_f
	puts "Warning: #{website_url.to_s} load time: #{website_load_time.to_s}" + performance_data
	exit 1
else
	puts "OK: #{website_url.to_s} load time: #{website_load_time.to_s}" + performance_data
	exit 0
end
