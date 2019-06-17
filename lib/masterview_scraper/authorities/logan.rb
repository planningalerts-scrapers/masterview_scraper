require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Logan
      def self.scrape_page(page)
        page.at("table.rgMasterTable").search("tr.rgRow,tr.rgAltRow").each do |tr|
          tds = tr.search('td').map{|t| t.inner_html.gsub("\r\n", "").strip}
          day, month, year = tds[2].split("/").map{|s| s.to_i}
          record = {
            "info_url" => (page.uri + tr.search('td').at('a')["href"]).to_s,
            "council_reference" => tds[1],
            "date_received" => Date.new(year, month, day).to_s,
            "description" => tds[3].gsub("&amp;", "&").split("<br>")[1].to_s.squeeze(" ").strip,
            "address" => tds[3].gsub("&amp;", "&").split("<br>")[0].gsub("\r", " ").gsub("<strong>","").gsub("</strong>","").squeeze(" ").strip,
            "date_scraped" => Date.today.to_s
          }
          puts "Saving record " + record['council_reference'] + " - " + record['address']
      #      puts record
          ScraperWiki.save_sqlite(['council_reference'], record)
        end
      end

      def self.scrape_and_save
        url = MasterviewScraper.url_last_14_days(
          "http://pdonline.logan.qld.gov.au/MasterViewUI/Modules/ApplicationMaster",
          "6" => "F"
        )

        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)

        # This is weird. There are two forms with the Agree / Disagree buttons. One of them
        # works the other one doesn't. Go figure.
        form = page.forms[1]
        button = form.button_with(value: "Agree")
        raise "Can't find agree button" if button.nil?
        page = form.submit(button)

        current_page_no = 1
        next_page_link = true

        while next_page_link
          puts "Scraping page #{current_page_no}..."
          scrape_page(page)

          current_page_no += 1
          next_page_link = page.at(".rgPageNext")
          page = Postback.click(next_page_link, page)
          next_page_link = nil if page.nil?
        end
      end
    end
  end
end
