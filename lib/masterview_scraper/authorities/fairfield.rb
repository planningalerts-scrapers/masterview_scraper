# frozen_string_literal: true

require "masterview_scraper/postback"

require "scraperwiki"
require "mechanize"

module MasterviewScraper
  module Authorities
    # Scraper for Fairfield
    module Fairfield

      def self.scrape_index_page(page)
        table = page.at("table")
        data = Table.extract_table(table)
        data.each do |row|
          record = {
            "info_url" => (page.uri + row[:url]).to_s,
            "council_reference" => row[:content]["Number"],
            "date_received" => Date.strptime(row[:content]["Submitted"], "%d/%m/%Y").to_s,
            # TODO: Do proper html entity conversion
            "description" => row[:content]["Details"].split("<br>")[1].gsub("&amp;", "&"),
            "address" => row[:content]["Details"].split("<br>")[0],
            "date_scraped" => Date.today.to_s
          }

          yield record
        end
      end

      def self.url
        MasterviewScraper.url_last_14_days(
          "https://openaccess.fairfieldcity.nsw.gov.au/OpenAccess/Modules/Applicationmaster",
          "4a" => 10,
          "6" => "F"
        )
      end

      def self.next_index_page(page)
        link = page.at(".rgPageNext")
        return if link.nil?

        Postback.click(link, page)
      end

      def self.scrape
        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)
        Pages::TermsAndConditions.click_agree(page)

        page = agent.get(url)

        while page
          scrape_index_page(page) do |record|
            yield record
          end
          page = next_index_page(page)
        end
      end

      def self.scrape_and_save
        scrape do |record|
          MasterviewScraper.save(record)
        end
      end
    end
  end
end
