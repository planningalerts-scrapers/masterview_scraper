require 'scraperwiki'
require 'rubygems'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Marion
      def self.scrape_and_save
        url = MasterviewScraper.url_with_period(
          "http://ecouncil.marion.sa.gov.au/datrackingui/modules/applicationmaster",
          "thisweek",
          "4a" => "7",
          "6" => "F"
        )

        agent = Mechanize.new

        doc = agent.get(url)
        Pages::TermsAndConditions.click_agree(doc)

        doc = agent.get(url)

        while doc
          Pages::Index.scrape(doc) do |record|
            MasterviewScraper.save(record)
          end
          doc = Pages::Index.next(doc)
        end
      end
    end
  end
end
