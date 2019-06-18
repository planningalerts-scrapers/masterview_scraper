require 'scraperwiki'
require 'openssl'
require 'mechanize'
require 'uri'

module MasterviewScraper
  module Authorities
    module Toowoomba
      def self.scrape_and_save
        url = MasterviewScraper.url_last_30_days(
          "https://pdonline.toowoombarc.qld.gov.au/Masterview/Modules/ApplicationMaster",
          "4a" => "\'488\',\'487\',\'486\',\'495\',\'521\',\'540\',\'496\',\'562\'",
          "6" => "F"
        )

        agent = Mechanize.new

        page = agent.get(url)
        Pages::TermsAndConditions.click_agree(page)

        # Get the page again
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
