require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module LakeMacquarie
      def self.scrape_and_save
        url = MasterviewScraper.url_with_period(
          "http://apptracking.lakemac.com.au/modules/ApplicationMaster",
          "thisweek",
          "4a" => "437",
          "5" => "T"
        )

        agent = Mechanize.new

        page = agent.get(url)
        Pages::TermsAndConditions.click_agree(page)

        page = agent.get(url)

        page.search("table.border").search("tr")[1].search("tr").each do |tr|
          if ( tr.search("td").count == 4 )
            tds = tr.search("td")
            if ( tds[1].inner_text.strip != 'Application' )

              day, month, year = tds[2].inner_text.strip.split("/").map{|s| s.to_i}
              record = {
                "council_reference" => tds[1].inner_text.strip,
                "address" => tds[3].inner_html.split("<br>")[0].strip,
                "description" => tds[3].inner_html.split("<br>")[1].strip.split("Description: ")[1],
                "info_url" => (page.uri + tds[0].at('a')["href"]).to_s,
                "date_scraped" => Date.today.to_s,
                "date_received" => Date.new(year, month, day).to_s
              }

              MasterviewScraper.save(record)
            end
          end
        end
      end
    end
  end
end
