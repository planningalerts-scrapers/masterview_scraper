require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module LakeMacquarie
      def self.scrape_and_save
        url = MasterviewScraper.url_with_period(
          "http://apptracking.lakemac.com.au/modules/ApplicationMaster",
          "thisweek",
          "4a" => "437",
          "5" => "T"
        )

        agent = Mechanize.new

        page = agent.get(url)
        Pages::TermsAndConditions.click_agree(page)

        page = agent.get(url)

        table = page.at("#_ctl5_lblData").at("table")
        Table.extract_table(table).each do |row|
          record = {
            "council_reference" => row[:content]["Application"],
            "address" => row[:content]["Description"].split("<br>")[0],
            "description" => row[:content]["Description"].split("<br>")[1].strip.split("Description: ")[1],
            "info_url" => (page.uri + row[:url]).to_s,
            "date_scraped" => Date.today.to_s,
            "date_received" => Date.strptime(row[:content]["Date Lodged"], "%d/%m/%Y").to_s
          }
          MasterviewScraper.save(record)
        end
      end
    end
  end
end
