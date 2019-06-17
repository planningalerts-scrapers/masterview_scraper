require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Logan
      def self.scrape_and_save
        url = MasterviewScraper.url_last_14_days(
          "http://pdonline.logan.qld.gov.au/MasterViewUI/Modules/ApplicationMaster",
          "6" => "F"
        )

        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)
        page = Pages::TermsAndConditions.click_agree(page)

        while page
          Pages::Index.scrape(page) do |record|
            MasterviewScraper.save(record)
          end
          page = Pages::Index.next(page)
        end
      end
    end
  end
end
