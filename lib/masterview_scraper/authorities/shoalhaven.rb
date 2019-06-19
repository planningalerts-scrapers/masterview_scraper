require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'date'

module MasterviewScraper
  module Authorities
    module Shoalhaven
      def self.scrape_and_save
        MasterviewScraper.scrape_and_save_period(
          url: "http://www3.shoalhaven.nsw.gov.au/masterviewUI/modules/ApplicationMaster",
          period: :thismonth,
          params: {
            "4a" => "25,13,72,60,58,56",
            "6" => "F"
          },
          state: "NSW"
        )
      end
    end
  end
end
