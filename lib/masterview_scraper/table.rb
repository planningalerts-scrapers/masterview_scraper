# frozen_string_literal: true

module MasterviewScraper
  # Utility for getting stuff out of html tables
  module Table
    def self.extract_table(table)
      headers = table.at("thead").search("th").map(&:inner_text)
      table.at("tbody").search("tr").map do |tr|
        row = tr.search("td").map { |td| td.inner_text.strip }
        {
          url: tr.at("a")["href"],
          content: headers.zip(row).to_h
        }
      end
    end
  end
end
