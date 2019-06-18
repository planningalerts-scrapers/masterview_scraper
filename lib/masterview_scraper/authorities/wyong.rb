require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Wyong
      def self.scrape_and_save
        url = MasterviewScraper.url_last_30_days(
          "http://wsconline.wyong.nsw.gov.au/applicationtracking/modules/applicationmaster",
          "4a" => "437",
          "5" => "T"
        )

        agent = Mechanize.new

        page = agent.get(url)
        Pages::TermsAndConditions.click_agree(page)

        # Doesn't redirect
        page = agent.get(url)

        # This system doesn't have paging. All the results come on a single page
        Pages::Index.scrape(page) do |record|
          MasterviewScraper.save(record)
        end
      end
    end
  end
end
