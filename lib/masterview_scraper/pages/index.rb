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
          details = row[:content]["Details"] ||
                    row[:content]["Property/Application Details"]
          details = details.split("<br>").map do |detail|
            strip_html(detail).squeeze(" ").strip
          end
          raise "Unexpected number of things in details" if details.length < 2 || details.length > 3

          yield(
            "info_url" => (page.uri + row[:url]).to_s,
            "council_reference" => row[:content]["Number"],
            "date_received" => Date.strptime(row[:content]["Submitted"], "%d/%m/%Y").to_s,
            "description" => (details.length == 3 ? details[2] : details[1]),
            "address" => details[0].gsub("\r", " "),
            # TODO: date_scraped should NOT be added here
            "date_scraped" => Date.today.to_s
          )
        end
      end

      # Returns the next page unless there is none in which case nil
      # TODO: Handle things when next isn't a button with a postback
      def self.next(page)
        link = page.at(".rgPageNext")
        return if link.nil?

        # So far come across two different setups. One where the next
        # button is a postback link and one where the next button is a
        # form submit button.
        if link["href"] || link["onclick"]
          Postback.click(link, page)
        else
          current_page_no = current_index_page_no(page)
          page_links = page.at(".rgNumPart")
          next_page_link = page_links&.search("a")
                                     &.find { |a| a.inner_text == (current_page_no + 1).to_s }
          (Postback.click(next_page_link, page) if next_page_link)
        end
      end

      def self.current_index_page_no(page)
        page.at(".rgCurrentPage").inner_text.to_i
      end

      # Strips any html tags and decodes any html entities
      # e.g. "<strong>Tea &amp; Cake<strong>" => "Tea & Cake"
      def self.strip_html(html)
        Nokogiri::HTML(html).inner_text
      end
    end
  end
end
