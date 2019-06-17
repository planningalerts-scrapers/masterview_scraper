require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module FraserCoast
      def self.url
        MasterviewScraper.url_last_14_days(
          "https://pdonline.frasercoast.qld.gov.au/Modules/ApplicationMaster",
          "4a" => "BPS%27,%27MC%27,%27OP%27,%27SB%27,%27MCU%27,%27ROL%27,%27OPWKS%27,%27QMCU%27,%27QRAL%27,%27QOPW%27,%27QDBW%27,%27QPOS%27,%27QSPS%27,%27QEXE%27,%27QCAR%27,%27ACA"
        )
      end

      def self.scrape
        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)

        Pages::TermsAndConditions.click_agree(page)

        # It doesn't even redirect to the correct place. Ugh
        page = agent.get(url)

        while page
          Pages::Index.scrape(page) do |record|
            # Add the state on to the end of the address
            record["address"] += ", QLD"
            yield record
          end
          page = Pages::Index.next(page)
        end
      end

      def self.scrape_and_save
        scrape do |record|
          MasterviewScraper.save(record)
        end
      end
    end
  end
end
