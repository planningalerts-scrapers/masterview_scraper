# frozen_string_literal: true

require "masterview_scraper/table"

require "scraperwiki"
require "mechanize"

module MasterviewScraper
  module Authorities
    # Scraper for Brisbane
    module Brisbane
      def self.url
        MasterviewScraper.url_last_14_days(
          "https://pdonline.brisbane.qld.gov.au/MasterViewUI/Modules/ApplicationMaster"
        )
      end

      def self.scrape
        agent = Mechanize.new
        # Read in a page
        page = agent.get(url)

        Pages::TermsAndConditions.click_agree(page)

        page = agent.get(url)

        while page
          scrape_index_page(page) do |record|
            yield record
          end
          page = next_index_page(page)
        end
      end

      def self.scrape_and_save
        scrape do |record|
          MasterviewScraper.save(record)
        end
      end

      def self.scrape_index_page(page)
        table = page.at("table#ctl00_cphContent_ctl01_ctl00_RadGrid1_ctl00")
        data = MasterviewScraper::Table.extract_table(table)
        data.each do |row|
          record = {
            "info_url" => (page.uri + row[:url]).to_s,
            "council_reference" => row[:content]["Application"].split("-")[0].strip,
            "date_received" => Date.strptime(row[:content]["Submitted"], "%d/%m/%Y").to_s,
            "description" => row[:content]["Application"].split("-", 2)[1].squeeze(" ").strip,
            "address" => row[:content]["Address"].squeeze(" ").strip,
            "date_scraped" => Date.today.to_s
          }

          yield record
        end
      end

      # Returns the next page unless there is none in which case nil
      def self.next_index_page(page)
        next_button = page.at(".rgPageNext")
        return if next_button.nil?

        Postback.click(next_button, page)
      end
    end
  end
end
