require 'scraperwiki'
require 'rubygems'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Hawkesbury
      def self.url
        MasterviewScraper.url_last_14_days(
          "http://council.hawkesbury.nsw.gov.au/MasterviewUI/Modules/applicationmaster",
          "4a" => "DA"
        )
      end

      def self.scrape_and_save
        agent = Mechanize.new

        # Jump through bollocks agree screen
        doc = agent.get(url)
        Pages::TermsAndConditions.click_agree(doc)

        doc = agent.get(url)

        while doc
          Pages::Index.scrape(doc) do |record|
            record["address"] += ", NSW"
            MasterviewScraper.save(record)
          end
          doc = Pages::Index.next(doc)
        end
      end
    end
  end
end
