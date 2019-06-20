# frozen_string_literal: true

module MasterviewScraper
  # This API endpoint only exists on recent versions of the system
  module GetApplicationsApi
    # Returns applications between those dates
    def self.scrape(base_url, start_date, end_date, agent)
      page = agent.post(
        base_url + "/Application/GetApplications",
        "start" => 0,
        # TODO: Do some kind of paging instead rather than just grabbing a large fixed number
        "length" => 1000,
        "json" => {
          "DateFrom" => start_date.strftime("%d/%m/%Y"),
          "DateTo" => end_date.strftime("%d/%m/%Y"),
          "DateType" => "1",
          "RemoveUndeterminedApplications" => false,
          "ShowOutstandingApplications" => false,
          "ShowExhibitedApplications" => false,
          "IncludeDocuments" => false
        }.to_json
      )

      JSON.parse(page.body)["data"].each do |application|
        details = application[4].split("<br/>")

        yield(
          "council_reference" => application[1],
          # Only picking out the first address
          "address" => details[0].strip,
          # TODO: Do this properly
          "description" => details[-1].gsub("<b>", "").gsub("</b>", "").squeeze(" "),
          "info_url" => (page.uri + "ApplicationDetails/" + application[0]).to_s,
          "date_scraped" => Date.today.to_s,
          "date_received" => Date.strptime(application[3], "%d/%m/%Y").to_s
        )
      end
    end
  end
end
