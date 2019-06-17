# frozen_string_literal: true

module MasterviewScraper
  module Pages
    # A page with a table of results of a search
    module Index
      def self.scrape(page)
        table = page.at("table.rgMasterTable")
        Table.extract_table(table).each do |row|
          yield(
            "info_url" => (page.uri + row[:url]).to_s,
            "council_reference" => row[:content]["Number"],
            "date_received" => Date.strptime(row[:content]["Submitted"], "%d/%m/%Y").to_s,
            "description" => strip_html(row[:content]["Details"].split("<br>")[1]).squeeze(" "),
            "address" => strip_html(row[:content]["Details"].split("<br>")[0]).strip + ", QLD",
            "date_scraped" => Date.today.to_s
          )
        end
      end

      # Strips any html tags and decodes any html entities
      # e.g. "<strong>Tea &amp; Cake<strong>" => "Tea & Cake"
      def self.strip_html(html)
        Nokogiri::HTML(html).inner_text
      end
    end
  end
end
