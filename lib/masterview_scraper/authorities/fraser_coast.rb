require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module FraserCoast
      def self.scrape_page(page)
        page.at("table.rgMasterTable").search("tr.rgRow,tr.rgAltRow").each do |tr|
          tds = tr.search('td').map{|t| t.inner_html.gsub("\r\n", "").strip}
          day, month, year = tds[2].split("/").map{|s| s.to_i}
          record = {
            "info_url" => (page.uri + tr.search('td').at('a')["href"]).to_s,
            "council_reference" => tds[1],
            "date_received" => Date.new(year, month, day).to_s,
            "description" => tds[3].gsub("&amp;", "&").split("<br>")[1].squeeze(" ").strip,
            "address" => tds[3].gsub("&amp;", "&").split("<br>")[0].gsub("\r", " ").gsub("<strong>","").gsub("</strong>","").squeeze(" ").strip + ", QLD",
            "date_scraped" => Date.today.to_s
          }

      #     puts record
          puts "Saving record " + record['council_reference'] + " - " + record['address']
          ScraperWiki.save_sqlite(['council_reference'], record)
        end
      end

      def self.url
        MasterviewScraper.url_last_14_days(
          "https://pdonline.frasercoast.qld.gov.au/Modules/ApplicationMaster",
          "page" => "found",
          "4a" => "BPS%27,%27MC%27,%27OP%27,%27SB%27,%27MCU%27,%27ROL%27,%27OPWKS%27,%27QMCU%27,%27QRAL%27,%27QOPW%27,%27QDBW%27,%27QPOS%27,%27QSPS%27,%27QEXE%27,%27QCAR%27,%27ACA",
          "6" => "F"
        )
      end

      def self.scrape_and_save
        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)

        Pages::TermsAndConditions.click_agree(page)

        # It doesn't even redirect to the correct place. Ugh
        page = agent.get(url)
        current_page_no = 1
        next_page_link = true

        while next_page_link
          puts "Scraping page #{current_page_no}..."
          scrape_page(page)

          page_links = page.at(".rgNumPart")
          if page_links
            next_page_link = page_links.search("a").find{|a| a.inner_text == (current_page_no + 1).to_s}
          else
            next_page_link = nil
          end
          if next_page_link
            current_page_no += 1
            page = Postback.click(next_page_link, page)
          end
        end
      end
    end
  end
end
