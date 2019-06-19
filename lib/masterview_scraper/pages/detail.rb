# frozen_string_literal: true

module MasterviewScraper
  module Pages
    # A page with (hopefully) all the details for an application
    module Detail
      def self.scrape(page)
        council_reference = page.at("#ctl03_lblHead")
        address = page.at("#lblLand")
        details = page.at("#lblDetails").at("td").inner_html.split("<br>").map do |detail|
          Pages::Index.strip_html(detail).strip
        end

        description = details[0][13..-1]
        date_received = details[1][11..-1]

        {
          council_reference: council_reference.inner_text.split(" ")[0],
          address: address.inner_text.strip.split("\n")[0].strip,
          description: description,
          info_url: page.uri.to_s,
          date_received: Date.strptime(date_received, "%d/%m/%Y").to_s
        }
      end
    end
  end
end
