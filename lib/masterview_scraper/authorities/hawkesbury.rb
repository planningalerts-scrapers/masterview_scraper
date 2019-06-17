require 'scraperwiki'
require 'rubygems'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Hawkesbury
      def self.clean_whitespace(a)
        a.gsub("\r", ' ').gsub("\n", ' ').squeeze(" ").strip
      end

      def self.scrape_table(doc)
        table = doc.at("table")
        data = MasterviewScraper::Table.extract_table(table)
        data.each do |row|
          # The details section actually consists of seperate parts
          details = row[:content]["Details"].split("<br>").map do |detail|
            Pages::Index.strip_html(detail).squeeze(" ").strip
          end

          record = {
            'info_url' => (doc.uri + row[:url]).to_s,
            'council_reference' => row[:content]["Number"],
            'date_received' => Date.strptime(row[:content]["Submitted"], "%d/%m/%Y").to_s,
            'address' => details[0] + ", NSW",
            'description' => details[2],
            'date_scraped' => Date.today.to_s
          }
          MasterviewScraper.save(record)
        end
      end

      def self.url
        MasterviewScraper.url_last_14_days(
          "http://council.hawkesbury.nsw.gov.au/MasterviewUI/Modules/applicationmaster",
          "4a" => "DA"
        )
      end

      def self.scrape_and_save
        agent = Mechanize.new

        # Jump through bollocks agree screen
        doc = agent.get(url)
        Pages::TermsAndConditions.click_agree(doc)

        doc = agent.get(url)

        while doc
          scrape_table(doc)
          doc = Pages::Index.next(doc)
        end
      end
    end
  end
end
