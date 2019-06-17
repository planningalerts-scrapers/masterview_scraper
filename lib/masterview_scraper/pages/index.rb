# frozen_string_literal: true

require "masterview_scraper/postback"

module MasterviewScraper
  module Pages
    # A page with a table of results of a search
    module Index
      def self.scrape(page)
        table = page.at("table.rgMasterTable")
        Table.extract_table(table).each do |row|
          # The details section actually consists of seperate parts
          details = row[:content]["Details"].split("<br>").map do |detail|
            strip_html(detail).squeeze(" ").strip
          end
          raise "Unexpected number of things in details" if details.length < 2 || details.length > 3

          yield(
            "info_url" => (page.uri + row[:url]).to_s,
            "council_reference" => row[:content]["Number"],
            "date_received" => Date.strptime(row[:content]["Submitted"], "%d/%m/%Y").to_s,
            "description" => (details.length == 3 ? details[2] : details[1]),
            "address" => details[0],
            "date_scraped" => Date.today.to_s
          )
        end
      end

      # Returns the next page unless there is none in which case nil
      # TODO: Handle things when next isn't a button with a postback
      def self.next(page)
        link = page.at(".rgPageNext")
        return if link.nil?

        Postback.click(link, page)
      end

      # Strips any html tags and decodes any html entities
      # e.g. "<strong>Tea &amp; Cake<strong>" => "Tea & Cake"
      def self.strip_html(html)
        Nokogiri::HTML(html).inner_text
      end
    end
  end
end
