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

        GetApplicationsApi.scrape(
          base_url,
          Date.today - 30,
          Date.today,
          agent
        ) do |record|
          MasterviewScraper.save(record)
        end
      end
    end
  end
end
