#!/usr/bin/env ruby

require "rss"
require "open-uri"

FEED_URL = "https://feeds.theoutline.com/tomorrow"

def main
  URI.parse(FEED_URL).open do |rss|
    feed = RSS::Parser.parse(rss)
    puts "Starting #{feed.channel.title} now"
    feed.items.each { |item| download_podcast(item) }
  end
end

def download_podcast(item)
  uri = URI(fetch_location(item.enclosure.url))

  with_output(item) do
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)

      title = friendly_title(item)

      open "output/#{title}.txt", "w" do |io|
        io.write(item.description)
      end

      http.request(request) do |response|
        open "output/#{title}.mp3", "w" do |io|
          response.read_body do |chunk|
            io.write chunk
          end
        end
      end
    end
  end
end

# https://stackoverflow.com/a/51072513
def fetch_location(url)
  response = Net::HTTP.get_response(URI.parse(url))
  result_url = response["location"]

  if response.is_a?(Net::HTTPRedirection)
    fetch_location(result_url)
  else
    url
  end
end

def friendly_title(item)
  item
    .title
    .tr(":", " ")
    .tr("/", "-")
end

def with_output(item)
  puts "🦔 Starting #{item.title}"
  yield
  puts "✅ Saved #{item.title}"
rescue => e
  puts "❌ Skipped #{item.title}. #{e.message}"
end

if __FILE__ == $0
  main
end
