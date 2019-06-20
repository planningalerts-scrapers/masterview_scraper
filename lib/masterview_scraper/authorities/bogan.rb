# frozen_string_literal: true

require 'json'

module MasterviewScraper
  module Authorities
    module Bogan
      def self.scrape_and_save
        base_url = "http://datracker.bogan.nsw.gov.au:81"

        agent = Mechanize.new

        page = agent.get(base_url + "/")

        MasterviewScraper::Pages::TermsAndConditions.click_agree(page)

        # Now we do a post to the API endpoint for getting applications

        page = agent.post(
          base_url + "/Application/GetApplications",
          "start" => 0,
          # TODO: Do some kind of paging instead rather than just grabbing a large fixed number
          "length" => 1000,
          "json" => {
            "DateFrom" => (Date.today - 30).strftime("%d/%m/%Y"),
            "DateTo" => Date.today.strftime("%d/%m/%Y"),
            "DateType" => "1",
            "RemoveUndeterminedApplications" => false,
            "ShowOutstandingApplications" => false,
            "ShowExhibitedApplications" => false,
            "IncludeDocuments" => false
          }.to_json
        )

        JSON.parse(page.body)["data"].each do |application|
          details = application[4].split("<br/>")

          record = {
            "council_reference" => application[1],
            # Only picking out the first address
            "address"           => details[0].strip,
            # TODO: Do this properly
            'description'       => details[-1].gsub("<b>", "").gsub("</b>", "").squeeze(" "),
            'info_url'          => (page.uri + "ApplicationDetails/" + application[0]).to_s,
            "date_scraped"      => Date.today.to_s,
            "date_received"     => Date.strptime(application[3], "%d/%m/%Y").to_s
          }
          MasterviewScraper.save(record)
        end
      end
    end
  end
end
