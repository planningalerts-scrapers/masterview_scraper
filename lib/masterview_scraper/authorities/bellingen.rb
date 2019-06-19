# frozen_string_literal: true

require "masterview_scraper/pages/terms_and_conditions"
require "masterview_scraper/pages/detail"

module MasterviewScraper
  module Authorities
    module Bellingen
      def self.scrape_and_save
        url = MasterviewScraper.url_with_period(
          "http://infomaster.bellingen.nsw.gov.au/MasterViewLive/modules/applicationmaster",
          # All applications in the last month
          "thismonth",
          "4a" => "DA,CDC,TA,MD",
          "6" => "F"
        )

        agent = Mechanize.new

        page = agent.get(url)

        Pages::TermsAndConditions.click_agree(page)

        # Get the page again
        page = agent.get(url)

        Pages::Index.scrape(page) do |record|
          # If index page doesn't have enough information then we need
          # to scrape the detail page
          if record[:info_url].nil? ||
             record[:council_reference].nil? ||
             record[:date_received].nil? ||
             record[:description].nil? ||
             record[:address].nil?

             info_page = agent.get(record[:info_url])
             record = Pages::Detail.scrape(info_page)
          end

          record = {
            "council_reference" => record[:council_reference],
            "address" => record[:address],
            "description" => record[:description],
            "info_url" => record[:info_url],
            "date_scraped" => Date.today.to_s,
            "date_received" => record[:date_received]
          }
          MasterviewScraper.save(record)
        end
      end
    end
  end
end
