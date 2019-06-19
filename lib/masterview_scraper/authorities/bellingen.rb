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
          info_page = agent.get(record[:info_url])
          record = scrape_detail_page(info_page)
          MasterviewScraper.save(record)
        end
      end
    end
  end
end
