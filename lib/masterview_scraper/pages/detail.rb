# frozen_string_literal: true

module MasterviewScraper
  module Pages
    # A page with (hopefully) all the details for an application
    module Detail
      def self.scrape(page)
        if page.at(".alert")&.inner_text&.strip ==
           "Sorry the application is not available. Please contact council for further details."
          nil
        elsif page.at("#details")
          scrape_new_version(page)
        else
          scrape_old_version(page)
        end
      end

      def self.scrape_old_version(page)
        council_reference = page.at("#ctl03_lblHead") ||
                            page.at("#ctl00_cphContent_ctl00_lblApplicationHeader")
        address = page.at("#lblLand") ||
                  page.at("#lblProp") ||
                  page.at("#lblprop") ||
                  page.at("#lblProperties")
        details = page.at("#lblDetails").inner_html.split("<br>").map do |detail|
          Pages::Index.strip_html(detail).strip
        end

        descriptions = []
        details.each do |detail|
          if detail =~ /^Description: (.*)/ || detail =~ /Activity:(.*)/
            description = Regexp.last_match(1).squeeze(" ").strip
            descriptions << description if description != ""
          end
        end
        description = descriptions.join(", ")

        if details[1].match(/^Submitted: (.*)/)
          date_received = Regexp.last_match(1)
        end

        {
          council_reference: (council_reference.inner_text.split(" ")[0] if council_reference),
          address: address.inner_text.strip.split("\n")[0].strip.gsub("\r", " ").squeeze(" "),
          description: description,
          info_url: page.uri.to_s,
          date_received: (Date.strptime(date_received, "%d/%m/%Y").to_s if date_received)
        }
      end

      APPROVED = [
        "Approved",
        "Approved - Delegation",
        "Approved - Council",
        "Approved - Council Staff",
        "Approved - Private Certifier",
        "Approved - IHAP (DAP)",
        "Approved Under Delegation",
        "Approved by Delegation",
        "Approved by Private Certifier",
        "Approved by Delegated Authority",
        "Approved by Delegated Officer",
        "Approved by Council",
        "Approved with Conditions",
        "Approved Council Certifier",
        "Modification Approved",
        "Issued",
        "Certificate Issued",
        "Certificate Issued by Private Certifier",
        "Certificate Issued CCC",
        "Interim Certificate Private Certifier",
        "Interim Certificate Issued CCC",
        "Planning Consent Granted - Private Cert",
        "Planning Consent Granted - Delegation",
        "Development Approval Granted-Delegation",
        "Development Approval-Privately Certified",
        "Variation To Application Approved",
        "Planning Consent Granted - CAP",
        "Planning Consent Granted SCAP",
        "Extension of Time Request Granted - PDPC",
        "Extension of Time Request Granted - DA",
        "Land Division Cert of Approval by SCAP",
        "Approved Septic with conditions",
        "State Significant Development Approval",
        # This one is a little bit tricky. It's basically saying that the council says
        # if you do "such and such in the next bit of time" we'll approve it.
        # So, it's kind of a conditional approval. We'll mark it as approved until we
        # can think of a better way of handling this
        "Deferred Commencement",
        "Deferred Approval",
        "Complete",
        "Conditional Consent - Council Staff",
        "Conditional Consent - Council",
        "Registration - Private Certification",
        "Exempt Development",
        "PC Approved Complying Development",
        "Privately Certified CC Approval",
        "Privately Certified Occ Cert Issued"
      ].freeze

      WITHDRAWN = [
        "Withdrawn",
        "Application Withdrawn",
        "Withdrawn by Applicant",
        "Withdrawn/Cancelled",
        "Withdrawn/cancelled - Other",
        # As far as I can tell this is where a person can withdraw an application
        # after it's been approved by the council. This is used to avoid multiple
        # DAs for the same property conflicting with each other.
        "Surrender Consent",
        "Cancelled/Surrendered",
        "Cancelled"
      ].freeze

      REJECTED = [
        "Rejected",
        "Rejected - Council Staff",
        "Refused",
        "Refused by Delegated Officer",
        # Haha. Withdrawn by staff - what a fantastic euphimism for rejected
        "Withdrawn by Staff"
      ]

      UNKNOWN = [
        "NO DA - Certificate Only",
        "Change in Workflow"
      ]

      # Get the data from the decision block as is but don't interpret it just yet
      def self.extract_decision_block(block)
        lines = block.search("td").map { |td| td.inner_text.strip.gsub("\r\n", " ") }
        result = {}
        lines.each do |line|
          field = case line
                  when /Application Status: (.*)/
                    :application_status
                  when /Determination Date:(.*)/
                    :determination_date
                  when /Determination Type: (.*)/
                    :determination_type
                  else
                    raise "Unexpected field in: #{line}"
                  end
          value = Regexp.last_match(1).strip
          value = nil if value == ""
          result[field] = value
        end
        result
      end

      def self.scrape_new_version(page)
        # TODO: Reinstate this code when all authorities are scraping the detail page
        decision_values = extract_decision_block(page.at("#decision").next_element)
        if decision_values[:application_status] == "Determined"
          date_decision = Date.strptime(decision_values[:determination_date], "%d/%m/%Y")
          if APPROVED.include?(decision_values[:determination_type])
            decision = "approved"
          elsif REJECTED.include?(decision_values[:determination_type])
            decision = "rejected"
          elsif WITHDRAWN.include?(decision_values[:determination_type])
            # TODO: Not sure this is the right thing to do
            decision = "withdrawn"
          # TODO: What DO we do with this??
          elsif decision_values[:determination_type] == "Withdrawn/Rejected"
            decision = "withdrawn/rejected"
          elsif UNKNOWN.include?(decision_values[:determination_type])
            # We're using this for a bucket where we don't know what the council values mean
            decision = "unknown"
          else
            raise "Unknown value of determination type: #{decision_values[:determination_type]}"
          end
        elsif decision_values[:application_status] == "In Progress" &&
              decision_values[:determination_type] == "Pending" &&
              decision_values[:determination_date].nil?
          # Do nothing
        else
          raise "Unexpected value for application status: #{decision_values[:application_status]}"
        end

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
          date_received: Date.strptime(date_received, "%d/%m/%Y").to_s,
          date_decision: date_decision.to_s,
          decision: decision
        }
      end
    end
  end
end
