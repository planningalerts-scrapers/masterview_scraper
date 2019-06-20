# frozen_string_literal: true

require "masterview_scraper/get_applications_api"

require 'json'

module MasterviewScraper
  module Authorities
    module Albury
      def self.scrape_and_save
        base_url = "https://eservice.alburycity.nsw.gov.au/ApplicationTracker"

        agent = Mechanize.new

        page = agent.get(base_url + "/")

        MasterviewScraper::Pages::TermsAndConditions.click_agree(page)

        GetApplicationsApi.scrape(
          base_url,
          Date.today - 10,
          Date.today,
          agent
        ) do |record|
          MasterviewScraper.save(record)
        end
      end
    end
  end
end
