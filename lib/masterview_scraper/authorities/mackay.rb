require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Mackay
      def self.postback(form, target, argument)
        form['__EVENTTARGET'] = target
        form['__EVENTARGUMENT'] = argument
        form.submit
      end

      def self.process_page(page)
        page.search('tr.rgRow,tr.rgAltRow').each do |tr|
          record = {
            "council_reference" => tr.search('td')[1].inner_text.gsub("\r\n", "").strip,
            "address" => tr.search('td')[3].inner_html.gsub("\r", " ").strip.split("<br>")[0],
            "description" => tr.search('td')[3].inner_html.gsub("\r", " ").strip.split("<br>")[1],
            "info_url" => (page.uri + tr.search('td').at('a')["href"]).to_s,
            "date_scraped" => Date.today.to_s,
            "date_received" => Date.parse(tr.search('td')[2].inner_text.gsub("\r\n", "").strip).to_s,
          }

          puts "Saving record " + record['council_reference'] + " - " + record['address']
      #       puts record
          ScraperWiki.save_sqlite(['council_reference'], record)
        end
      end

      def self.scrape_and_save
        url = MasterviewScraper.url_last_30_days(
          "https://planning.mackay.qld.gov.au/masterview/Modules/Applicationmaster",
          "4a" => "443,444,445,446,487,555,556,557,558,559,560,564",
          "6" => "F"
        )

        agent = Mechanize.new
        page = agent.get(url)

        if page.search('div.rgNumPart a').empty?
          process_page(page)
        else
          i = 1
          page.search('div.rgNumPart a').each do |a|
            puts "scraping page " + i.to_s
            target, argument = a[:href].scan(/'([^']*)'/).flatten
            page = postback(page.form, target, argument)

            process_page(page)
            i += 1
          end
        end
      end
    end
  end
end
