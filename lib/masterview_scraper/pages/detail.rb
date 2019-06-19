# frozen_string_literal: true

module MasterviewScraper
  module Pages
    # A page with (hopefully) all the details for an application
    module Detail
      def self.scrape(page)
        details = (page / '//*[@id="lblDetails"]')

        council_reference = (page / '//*[@id="ctl03_lblHead"]').inner_text.split(" ")[0]
        {
          council_reference: council_reference,
          address: (page / '//*[@id="lblLand"]').inner_text.strip.split("\n")[0].strip,
          description: details.at("td").inner_text.split("\r")[1].strip[13..-1],
          info_url: page.uri.to_s,
          date_received: Date.strptime(
            details.at("td").inner_html.split("<br>")[1].strip[11..-1], "%d/%m/%Y"
          ).to_s
        }
      end
    end
  end
end
