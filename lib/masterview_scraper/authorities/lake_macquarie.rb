require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module LakeMacquarie
      def self.scrape_and_save
        url = "http://apptracking.lakemac.com.au/modules/ApplicationMaster/default.aspx?page=found&1=thisweek&4a=437&5=T"

        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)

        # This is weird. There are two forms with the Agree / Disagree buttons. One of them
        # works the other one doesn't. Go figure.
        form = page.forms[0]
        button = form.button_with(value: /Agree/)
        raise "Can't find agree button" if button.nil?
        page = form.submit(button)

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


              puts "Saving record " + record['council_reference'] + " - " + record['address']
        #         puts record
              ScraperWiki.save_sqlite(['council_reference'], record)
            end
          end
        end
      end
    end
  end
end
