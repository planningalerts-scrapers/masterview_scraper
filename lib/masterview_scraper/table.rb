# frozen_string_literal: true

module MasterviewScraper
  # Utility for getting stuff out of html tables
  module Table
    def self.extract_table(table)
      headers = header_elements(table).map { |th| th.inner_text.strip }
      body_rows(table).map do |tr|
        row = tr.search("td").map { |td| td.inner_html.strip }
        {
          url: tr.at("a")["href"],
          content: headers.zip(row).to_h
        }
      end
    end

    def self.header_elements(table)
      # If it's actually got a header use that
      if table.at("thead")
        table.at("thead").search("th")
      # Otherwise just use the first row
      else
        table.at("tr").search("td")
      end
    end

    def self.header_row(table)
      # If it's actually got a header use that
      if table.at("thead")
        table.at("thead").at("tr")
      # Otherwise just use the first row
      else
        table.at("tr")
      end
    end

    def self.body_rows(table)
      # If it's actually got a body use that
      if table.at("tbody")
        table.at("tbody").search("tr")
      # Otherwise assume the first row is the header and
      # return everything else
      else
        table.search("tr")[1..-1]
      end
    end
  end
end
