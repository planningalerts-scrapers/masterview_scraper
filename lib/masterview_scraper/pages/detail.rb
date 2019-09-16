# frozen_string_literal: true

module MasterviewScraper
  module Pages
    # A page with (hopefully) all the details for an application
    module Detail
      def self.scrape(page)
        if page.at("#details")
          scrape_new_version(page)
        else
          scrape_old_version(page)
        end
      end

      def self.scrape_old_version(page)
        council_reference = page.at("#ctl03_lblHead") ||
                            page.at("#ctl00_cphContent_ctl00_lblApplicationHeader")
        address = page.at("#lblLand") ||
                  page.at("#lblProp")
        details = page.at("#lblDetails").inner_html.split("<br>").map do |detail|
          Pages::Index.strip_html(detail).strip
        end

        description = details[0].match(/^Description: (.*)/)[1].squeeze(" ")
        date_received = details[1].match(/^Submitted: (.*)/)[1]

        {
          council_reference: council_reference.inner_text.split(" ")[0],
          address: address.inner_text.strip.split("\n")[0].strip,
          description: description,
          info_url: page.uri.to_s,
          date_received: Date.strptime(date_received, "%d/%m/%Y").to_s
        }
      end

      def self.scrape_new_version(page)
        {
          address: page.at("#properties").next_element.inner_text.strip.split("(")[0].strip
        }
      end
    end
  end
end
