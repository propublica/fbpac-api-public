require 'restclient'
require 'json'

# compares output of some representative URLs between Rust and Ruby
# printing out the diff
# if all you get is a list of URLs


success = true

url_pairs = [
	["http://localhost:8080/facebook-ads/recent_advertisers",
	"http://localhost:3000/ads/recent_advertisers"],

	["http://localhost:8080/facebook-ads/advertisers",
	"http://localhost:3000/ads/advertisers"],

	# Does not exist	
	# ["http://localhost:8080/facebook-ads/by_target",
	# "http://localhost:3000/ads/by_target"],

	["http://localhost:8080/facebook-ads/ads",
	"http://localhost:3000/ads"],

	["http://localhost:8080/facebook-ads/ads?search=utah&page=1",
	"http://localhost:3000/ads?search=utah&page=1"],


	["http://localhost:8080/facebook-ads/ads/?advertisers=%5B%22Donald+J.+Trump%22%5D",
	"http://localhost:3000/ads/?advertisers=%5B%22Donald+J.+Trump%22%5D"],
	["http://localhost:8080/facebook-ads/ads/?targets=%5B%7B%22target%22%3A%22Gender%22%7D%5D",
	"http://localhost:3000/ads/?targets=%5B%7B%22target%22%3A%22Gender%22%7D%5D"],
	["http://localhost:8080/facebook-ads/ads/?entities=%5B%7B%22entity%22%3A%22Planned+Parenthood%22%7D%5D",
	"http://localhost:3000/ads/?entities=%5B%7B%22entity%22%3A%22Planned+Parenthood%22%7D%5D"],
	["http://localhost:8080/facebook-ads/ads/?advertisers=%5B%22ACLU%22%5D&targets=%5B%7B%22target%22%3A%22Gender%22%7D%5D&entities=%5B%7B%22entity%22%3A%22Donald+Trump%22%7D%5D",
	"http://localhost:3000/ads/?advertisers=%5B%22ACLU%22%5D&targets=%5B%7B%22target%22%3A%22Gender%22%7D%5D&entities=%5B%7B%22entity%22%3A%22Donald+Trump%22%7D%5D"],

	["http://localhost:8080/facebook-ads/ads/23842729393560096",
	"http://localhost:3000/ads/23842729393560096"],
	# ["http://localhost:8080/facebook-ads/ads/23842702386470204", # should 404 because nonpolitical
	# "http://localhost:3000/ads/23842702386470204"], # should 404 because nonpolitical
	# ["http://localhost:8080/facebook-ads/ads/6108535208920", # should 404 because not en-US
	# "http://localhost:3000/ads/6108535208920"], # should 404 because not en-US
]
require 'json-diff'
url_pairs.each do |rust_url, ruby_url|
	puts rust_url
	rust_json = JSON.parse(RestClient.get(rust_url, {"Accept-Language": "null;q=1.0", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImplcmVteS5tZXJyaWxsQHByb3B1YmxpY2Eub3JnIn0.DjSfigjAcDXzyLbE_fXQLwwvLwMmexyq-wxOZ9so_L0"}))
	puts ruby_url
	ruby_json = JSON.parse(RestClient.get(ruby_url, {"Accept-Language": "null;q=1.0", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImplcmVteS5tZXJyaWxsQHByb3B1YmxpY2Eub3JnIn0.DjSfigjAcDXzyLbE_fXQLwwvLwMmexyq-wxOZ9so_L0"}))


	# exclude differences that are just differences in how Ruby and Rust serialize dates and floats.
	real_diffs = JsonDiff.diff(ruby_json, rust_json, {include_was: true, moves: false}).reject{|obj| obj["op"] == "replace" && obj["was"].to_s[0..10] == obj["value"].to_s[0..10] }

	success = success && real_diffs.empty?
	puts real_diffs
end
if success
	puts "no diffs, you're good :)"
else
	puts "there were differences, you have some changes to make"
end