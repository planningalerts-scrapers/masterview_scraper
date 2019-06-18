require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Wyong
      def self.scrape_and_save
        url = MasterviewScraper.url_with_period(
          "http://wsconline.wyong.nsw.gov.au/applicationtracking/modules/applicationmaster",
          "thisweek",
          "4a" => "437",
          "5" => "T"
        )

        agent = Mechanize.new

        page = agent.get(url)
        Pages::TermsAndConditions.click_agree(page)

        # Doesn't redirect
        page = agent.get(url)

        # TODO: Handle paging. Currently ignores it
        Pages::Index.scrape(page) do |record|
          MasterviewScraper.save(record)
        end
      end
    end
  end
end
