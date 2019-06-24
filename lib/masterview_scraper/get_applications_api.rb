# frozen_string_literal: true

require "json"

module MasterviewScraper
  # This API endpoint only exists on recent versions of the system
  module GetApplicationsApi
    # Returns applications between those dates
    def self.scrape(url:, start_date:, end_date:, agent:, long_council_reference:, types:)
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
        "start" => 0,
        # TODO: Do some kind of paging instead rather than just grabbing a large fixed number
        "length" => 1000,
        "json" => json.to_json
      )

      JSON.parse(page.body)["data"].each do |application|
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
    end
  end
end
