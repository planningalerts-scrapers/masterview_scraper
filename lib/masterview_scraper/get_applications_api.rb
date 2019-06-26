# frozen_string_literal: true

require "json"

module MasterviewScraper
  # This API endpoint only exists on recent versions of the system
  module GetApplicationsApi
    # Returns applications between those dates
    def self.scrape(url:, start_date:, end_date:, agent:, long_council_reference:,
                    types:, page_size: 100)
      page_no = 0
      # Start with the assumption that there is at least one records to be returned
      total_records = 1

      while total_records > page_no * page_size
        total_records = scrape_page(
          offset: page_no * page_size, limit: page_size, url: url,
          start_date: start_date, end_date: end_date,
          agent: agent, long_council_reference: long_council_reference, types: types
        ) do |record|
          yield record
        end
        page_no += 1
      end
    end

    def self.scrape_page(
      offset:, limit:, url:, start_date:, end_date:, agent:, long_council_reference:, types:
    )
      json = {
        "DateFrom" => start_date.strftime("%d/%m/%Y"),
        "DateTo" => end_date.strftime("%d/%m/%Y"),
        "DateType" => "1",
        "RemoveUndeterminedApplications" => false,
        "ShowOutstandingApplications" => false,
        "ShowExhibitedApplications" => false,
        "IncludeDocuments" => false
      }
      json["ApplicationType"] = types.join(",") if types

      page = agent.post(
        url + "/Application/GetApplications",
        "start" => offset,
        "length" => limit,
        "json" => json.to_json
      )

      result = JSON.parse(page.body)
      result["data"].each do |application|
        details = application[4].split("<br/>")
        # TODO: Do this properly
        description = details[-1].gsub("<b>", "").gsub("</b>", "").squeeze(" ")
        # If no description then use the application type as the description
        description = application[2] if description.empty?
        yield(
          "council_reference" => long_council_reference ? application[0] : application[1],
          # Only picking out the first address
          "address" => details[0].strip,
          "description" => description,
          "info_url" => (page.uri + "ApplicationDetails/" + application[0]).to_s,
          "date_scraped" => Date.today.to_s,
          "date_received" => Date.strptime(application[3], "%d/%m/%Y").to_s
        )
      end

      # Return the total number of records (not just what's in this page)
      result["recordsTotal"]
    end
  end
end
