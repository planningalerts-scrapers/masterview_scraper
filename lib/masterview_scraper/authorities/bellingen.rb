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
        # Visit each DA page so we can get the details
        (page / '//*[@id="ctl03_lblData"]').search("a").each do |a|
          info_page = agent.get(agent.page.uri + URI.parse(a.attributes["href"]))
          yield scrape_detail_page(info_page)
        end
      end

      def self.scrape_and_save
        agent = Mechanize.new

        # All applications in the last month
        url = "http://infomaster.bellingen.nsw.gov.au/MasterViewLive/modules/applicationmaster/default.aspx?page=found&1=thismonth&4a=DA,CDC,TA,MD&6=F"
        page = agent.get(url)

        Pages::TermsAndConditions.click_agree(page)

        # Get the page again
        page = agent.get(url)

        scrape_index_page(page, agent) do |record|
          #    puts record
          puts "Saving record " + record["council_reference"]
          ScraperWiki.save_sqlite(["council_reference"], record)
        end
      end
    end
  end
end
