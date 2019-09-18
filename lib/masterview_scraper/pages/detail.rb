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

      APPROVED = [
        "Approved - Delegation",
        "Approved - Council",
        "Approved Under Delegation",
        "Modification Approved",
        "Certificate Issued"
      ].freeze

      def self.scrape_new_version(page)
        # TODO: Reinstate this code when all authorities are scraping the detail page
        # decision_lines = page.at("#decision").next_element.search("td").map { |td| td.inner_text.strip.gsub("\r\n", " ") }
        # date_decision = decision_lines[1].match(/^Determination Date:(.*)/)[1].strip
        # date_decision = nil if date_decision == ""
        # decision = decision_lines[2].match(/Determination Type:(.*)/)[1].strip
        # if APPROVED.include?(decision)
        #   decision = "approved"
        # elsif decision == "Pending"
        #   decision = nil
        # else
        #   raise "Unknown value of decision: #{decision}"
        # end

        properties = page.at("#properties").next_element
        details = page.at("#details").next_element
        date_received = details.at("td:contains('Submitted Date:')").next_element.inner_text.strip
        description = details.at("td:contains('Description:')").next_element.inner_text
        application_type = details.at("td:contains('Application Type:')").next_element.inner_text
        # If description is empty use application type instead
        description = application_type if description == ""
        {
          address: properties.inner_text.strip.split("(")[0].strip,
          description: description,
          date_received: Date.strptime(date_received, "%d/%m/%Y").to_s
          # TODO: Reinstate this code when all authorities are scraping the detail page
          # date_decision: (Date.strptime(date_decision, "%d/%m/%Y").to_s if date_decision),
          # decision: decision
        }
      end
    end
  end
end
