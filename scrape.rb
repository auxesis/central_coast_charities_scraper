require "scraperwiki"
require "faraday"
require "addressable"
require "reverse_markdown"
require "active_support/core_ext/hash"

STDOUT.sync = true

def agent
  return @agent if @agent
  default_headers = { 'User-Agent': "central_coast_charities_scraper (#{RUBY_PLATFORM}) https://github.com/auxesis/central_coast_charities_scraper" }
  @agent = Faraday.new(headers: default_headers) do |f|
    f.response :json
  end
  @agent
end

def base_url
  "https://www.acnc.gov.au"
end

#  {
#    url: course_url,
#    id: Addressable::URI.parse(course_url).query_values["course_id"].to_i,
#    name: response.search(".ax-course-name").first.text.strip,
#    code: response.search(".ax-course-code").first.text.strip,
#    description: response.search(".ax-cd-description").first.text.strip,
#    target_audience: response.search(".ax-cd-target .ax-course-introduction").first.text.strip,
#    learning_outcomes: ReverseMarkdown.convert(response.search(".ax-cd-learning-outcomes .ax-course-content-list").first.text),
#    course_content: ReverseMarkdown.convert(response.search(".ax-cd-learning-methods .ax-course-content-list").first.to_html),
#    learning_methods: ReverseMarkdown.convert(response.search(".ax-cd-learning-methods .ax-course-introduction").first.to_html),
#    course_entry_requirements: extract_course_entry_requirements(response),
#    workshops: extract_course_workshops(response),
#    last_seen_at: Time.now,
#  }

def postcodes
  %i[2250 2251 2256 2257 2260 2775]
end

def scrape_index_for(postcode:)
  # Do the initial search
  puts "[INFO] Searching for charities in #{postcode}"
  index = []
  postcode_url = "https://www.acnc.gov.au/api/dynamics/search/charity?location=#{postcode}&items_per_page=100"
  response = agent.get(postcode_url)
  index += response.body["results"].map { |r| r["data"].merge("id" => r["uuid"]) }

  puts "[INFO] Found #{response.body["pager"]["total_results"]} charities in #{postcode}"
  # Then request additional pages
  1.upto(response.body["pager"]["total_pages"] - 1).map { |i|
    page = i
    postcode_page_url = "https://www.acnc.gov.au/api/dynamics/search/charity?location=#{postcode}&items_per_page=100&page=#{page}"
    response = agent.get(postcode_page_url)
    index += response.body["results"].map { |r| r["data"].merge("id" => r["uuid"]) }
  }
  index
end

def interesting_keys
  ["Name", "Status", "Abn", "AddressLine1", "AddressLine2", "AddressSuburb", "AddressStateOrProvince", "AddressPostalCode", "AddressCountry", "Website", "Email", "Phone", "CharitySize", "AFSEmail", "uuid", "AFSAddressPostalCode", "AddressSuburbStatePostcode"]
end

def scrape_charity(index)
  charity_url = "https://www.acnc.gov.au/api/dynamics/entity/#{index["id"]}"
  response = agent.get(charity_url)
  response.body["data"].slice(*interesting_keys)
end

def main
  charity_index = postcodes.map { |postcode|
    scrape_index_for(postcode: postcode)
  }.flatten

  puts "[INFO] Scraping #{charity_index.size} charities across #{postcodes.size} postcodes"

  charities = charity_index[0..9].map do |index|
    puts "[INFO] Scraping #{index["id"]}: #{index["Name"]}"
    data = scrape_charity(index)
    data
  end

  ScraperWiki.save_sqlite(%w[uuid], charities, "charities")

  puts "[INFO] Charities scraped: #{charities.size}"
end

main() if $PROGRAM_NAME == $0
