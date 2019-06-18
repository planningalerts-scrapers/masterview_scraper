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
        Pages::Index.scrape(page) do |record|
          yield record
        end
      end
    end
  end
end
