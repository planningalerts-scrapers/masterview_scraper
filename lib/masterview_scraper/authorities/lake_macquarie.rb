require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module LakeMacquarie
      def self.scrape_and_save
        # Scraping from Masterview 2.0
        case ENV['MORPH_PERIOD']
          when 'lastmonth'
          	period = "&1=lastmonth"
          when 'thismonth'
          	period = "&1=thismonth"
          else
            unless ENV['MORPH_PERIOD'] == nil
              matches = ENV['MORPH_PERIOD'].scan(/^([0-9]{4})-(0[1-9]|1[0-2])$/)
              unless matches.empty?
                period = "&1=" + Date.new(matches[0][0].to_i, matches[0][1].to_i, 1).strftime("%d/%m/%Y")
                period = period + "&2=" + Date.new(matches[0][0].to_i, matches[0][1].to_i, -1).strftime("%d/%m/%Y")
              else
                period = "&1=thisweek"
                ENV['MORPH_PERIOD'] = 'thisweek'
              end
            else
              period = "&1=thisweek"
              ENV['MORPH_PERIOD'] = 'thisweek'
            end
        end
        puts "Getting data in `" + ENV['MORPH_PERIOD'] + "`, changable via MORPH_PERIOD environment"

        url = "http://apptracking.lakemac.com.au/modules/ApplicationMaster/default.aspx?page=found" + period + "&4a=437&5=T"

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
