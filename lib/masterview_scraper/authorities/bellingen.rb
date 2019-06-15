# frozen_string_literal: true

require "masterview_scraper/pages/terms_and_conditions"

module MasterviewScraper
  module Authorities
    # Scraper for Bellingen
    module Bellingen
      def self.scrape_detail_page(info_page)
        details = (info_page / '//*[@id="lblDetails"]')

        council_reference = (info_page / '//*[@id="ctl03_lblHead"]').inner_text.split(" ")[0]
        {
          "council_reference" => council_reference,
          "address" => (info_page / '//*[@id="lblLand"]').inner_text.strip.split("\n")[0].strip,
          "description" => details.at("td").inner_text.split("\r")[1].strip[13..-1],
          "info_url" => info_page.uri.to_s,
          "date_scraped" => Date.today.to_s,
          "date_received" => Date.strptime(
            details.at("td").inner_html.split("<br>")[1].strip[11..-1], "%d/%m/%Y"
          ).to_s
        }
      end

      def self.scrape_index_page(page, agent)
        table = (page / '//*[@id="ctl03_lblData"]').at("table")
        data = MasterviewScraper::Table.extract_table(table)
        data.each do |row|
          info_page = agent.get(row[:url])
          yield scrape_detail_page(info_page)
        end
      end

      def self.url
        MasterviewScraper.url_with_period(
          "http://infomaster.bellingen.nsw.gov.au/MasterViewLive/modules/applicationmaster",
          # All applications in the last month
          "thismonth",
          "page" => "found",
          "4a" => "DA,CDC,TA,MD",
          "6" => "F"
        )
      end

      def self.scrape
        agent = Mechanize.new

        page = agent.get(url)

        Pages::TermsAndConditions.click_agree(page)

        # Get the page again
        page = agent.get(url)

        scrape_index_page(page, agent) do |record|
          yield record
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
