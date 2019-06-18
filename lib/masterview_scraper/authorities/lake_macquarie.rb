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

        # It looks like this index page doesn't have pagination
        scrape_index_page(page) do |record|
          MasterviewScraper.save(record)
        end
      end

      def self.scrape_index_page(page)
        table = page.at("#_ctl5_lblData").at("table")
        Table.extract_table(table).each do |row|
          yield(
            "info_url" => (page.uri + row[:url]).to_s,
            "council_reference" => row[:content]["Application"],
            "date_received" => Date.strptime(row[:content]["Date Lodged"], "%d/%m/%Y").to_s,
            "description" => row[:content]["Description"].split("<br>")[1].strip.split("Description: ")[1],
            "address" => row[:content]["Description"].split("<br>")[0],
            "date_scraped" => Date.today.to_s
          )
        end
      end
    end
  end
end
