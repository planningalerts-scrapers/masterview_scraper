# frozen_string_literal: true

require "masterview_scraper/postback"

require "scraperwiki"
require "mechanize"

module MasterviewScraper
  module Authorities
    # Scraper for Fairfield
    module Fairfield
      def self.url
        MasterviewScraper.url_last_14_days(
          "https://openaccess.fairfieldcity.nsw.gov.au/OpenAccess/Modules/Applicationmaster",
          "4a" => 10
        )
      end

      def self.scrape
        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)
        Pages::TermsAndConditions.click_agree(page)

        page = agent.get(url)

        while page
          Pages::Index.scrape(page) do |record|
            yield record
          end
          page = Pages::Index.next(page)
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
