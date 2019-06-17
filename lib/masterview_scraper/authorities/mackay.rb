require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Mackay
      def self.scrape_and_save
        url = MasterviewScraper.url_last_30_days(
          "https://planning.mackay.qld.gov.au/masterview/Modules/Applicationmaster",
          "4a" => "443,444,445,446,487,555,556,557,558,559,560,564",
          "6" => "F"
        )

        agent = Mechanize.new
        page = agent.get(url)
        
        if Pages::TermsAndConditions.on_page?(page)
          Pages::TermsAndConditions.click_agree(page)
          page = agent.get(url)
        end

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
