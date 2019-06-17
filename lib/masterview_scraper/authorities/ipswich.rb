require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Ipswich
      def self.scrape_page(page)
        table = page.at("table.rgMasterTable")
        Table.extract_table(table).each do |row|
          # The details section actually consists of seperate parts
          details = row[:content]["Details"] ||
                    row[:content]["Property/Application Details"]
          details = details.split("<br>").map do |detail|
            Pages::Index.strip_html(detail).squeeze(" ").strip
          end
          raise "Unexpected number of things in details" if details.length < 2 || details.length > 3

          record = {
            "info_url" => (page.uri + row[:url]).to_s,
            "council_reference" => row[:content]["Number"],
            "date_received" => Date.strptime(row[:content]["Submitted"], "%d/%m/%Y").to_s,
            "description" => details[1],
            "address" => details[0].gsub("\r", " "),
            "date_scraped" => Date.today.to_s
          }
          MasterviewScraper.save(record)
        end
      end

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
          scrape_page(page)
          page = Pages::Index.next(page)
        end
      end
    end
  end
end
