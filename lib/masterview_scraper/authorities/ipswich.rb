require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Ipswich
      def self.scrape_page(page)
        page.at("table.rgMasterTable").search("tr.rgRow,tr.rgAltRow").each do |tr|
          tds = tr.search('td').map{|t| t.inner_html.gsub("\r\n", "").strip}
          day, month, year = tds[2].split("/").map{|s| s.to_i}
          record = {
            "info_url" => (page.uri + tr.search('td').at('a')["href"]).to_s,
            "council_reference" => tds[1],
            "date_received" => Date.new(year, month, day).to_s,
            "description" => tds[3].gsub("&amp;", "&").split("<br>")[1].squeeze(" ").strip,
            "address" => tds[3].gsub("&amp;", "&").split("<br>")[0].gsub("\r", " ").squeeze(" ").strip,
            "date_scraped" => Date.today.to_s
          }
          #p record
          puts "Saving record " + record['council_reference'] + ", " + record['address']
          ScraperWiki.save_sqlite(['council_reference'], record)
        end
      end

      def self.next_page(page, current_page_no)
        page_links = page.at(".rgNumPart")
        if page_links
          next_page_link = page_links.search("a").find{|a| a.inner_text == (current_page_no + 1).to_s}
        else
          next_page_link = nil
        end
        if next_page_link
          page = Postback.click(next_page_link, page)
        else
          page = nil
        end
        page
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
        current_page_no = 1

        while page
          puts "Scraping page #{current_page_no}..."
          scrape_page(page)

          page = next_page(page, current_page_no)
          current_page_no += 1
        end
      end
    end
  end
end
