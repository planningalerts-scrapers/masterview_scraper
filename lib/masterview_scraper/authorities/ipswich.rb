require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Ipswich
      def self.scrape_and_save
        url = MasterviewScraper.url_last_14_days(
          "http://pdonline.ipswich.qld.gov.au/pdonline/modules/applicationmaster",
          # TODO: Don't know what this parameter "5" does
          { "5" => "T" }
        )

        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)
        Pages::TermsAndConditions.click_agree(page)

        page = agent.get(url)

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
