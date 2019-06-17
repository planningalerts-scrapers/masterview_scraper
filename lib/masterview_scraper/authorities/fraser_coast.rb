require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module FraserCoast
      # Strips any html tags and decodes any html entities
      # e.g. "<strong>Tea &amp; Cake<strong>" => "Tea & Cake"
      def self.strip_html(html)
        Nokogiri::HTML(html).inner_text
      end

      def self.scrape_page(page)
        table = page.at("table.rgMasterTable")
        # TODO: Make extract_table return html nodes
        data = Table.extract_table(table)
        data.each do |row|
          record = {
            "info_url" => (page.uri + row[:url]).to_s,
            "council_reference" => row[:content]["Number"],
            "date_received" => Date.strptime(row[:content]["Submitted"], "%d/%m/%Y").to_s,
            "description" => strip_html(row[:content]["Details"].split("<br>")[1]).squeeze(" "),
            "address" => strip_html(row[:content]["Details"].split("<br>")[0]).strip + ", QLD",
            "date_scraped" => Date.today.to_s
          }
          MasterviewScraper.save(record)
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

      def self.current_index_page_no(page)
        page.at(".rgCurrentPage").inner_text.to_i
      end

      def self.next_index_page(page)
        current_page_no = current_index_page_no(page)
        page_links = page.at(".rgNumPart")
        next_page_link = if page_links
          page_links.search("a").find{|a| a.inner_text == (current_page_no + 1).to_s}
        end
        (Postback.click(next_page_link, page) if next_page_link)
      end

      def self.scrape_and_save
        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)

        Pages::TermsAndConditions.click_agree(page)

        # It doesn't even redirect to the correct place. Ugh
        page = agent.get(url)

        while page
          scrape_page(page)
          page = next_index_page(page)
        end
      end
    end
  end
end
