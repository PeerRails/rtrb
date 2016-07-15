require 'feedjira'
require 'csv'
require 'rufus-scheduler'
require "logger"

RTFOLDER = ENV["RTFOLDER"] || "/home/prails/rtorrent/watch/start"
FILTERCSV = "filters.csv"
LOGGER = Logger.new("info.log")

def feed_rss
	url = "http://www.nyaa.se/?page=rss&cats=1_37"
	return Feedjira::Feed.fetch_and_parse url
end

def get_filters
	`touch filter.lock`
	filters = []
	CSV.foreach(FILTERCSV, :headers => true) do |row|
		filters.push row["FILTER"]
	end
	return filters
end

def match_filter(filters, title)
	filters.each do |filter|
		if title.match(filter)
			return true
		end
	end
	return false
end

def feed_filter(feed)
	filters = get_filters
	feed.entries.each do |entry|
		if match_filter(filters, entry.title)
			filename = "#{RTFOLDER}/#{entry.title}.torrent"
			puts filename
			unless File.exists?(filename)
				`wget -O "#{filename}" #{entry.url}`
				LOGGER.info("Downloaded #{filename}")
			end
		end
	end
	`rm filter.lock`
end

scheduler = Rufus::Scheduler.new

scheduler.in '5m' do
	LOGGER.info("Starting")
	feed_filter feed_rss
	LOGGER.info("sleeping")
end
scheduler.join
