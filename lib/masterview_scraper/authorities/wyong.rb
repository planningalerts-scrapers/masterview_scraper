require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Wyong
      def self.scrape_page(page)
        page.at("table table").search("tr.tableLine").each do |tr|
          tds = tr.search('td').map{|t| t.inner_html.gsub("\r\n", "").strip}
          day, month, year = tds[2].split("/").map{|s| s.to_i}

          description = tds[3].gsub("&amp;", "&").split("<br>")[1] rescue nil
          if description.nil?
            description = "Not supplied"
          else
            description = description.squeeze(" ").strip
          end

          record = {
            "info_url" => (page.uri + tr.at('td').at('a')["href"]).to_s,
            "council_reference" => tds[1].squeeze(" ").strip,
            "date_received" => Date.new(year, month, day).to_s,
            "description" => description,
            "address" => tds[3].gsub("&amp;", "&").split("<br>")[0].gsub("\r", " ").gsub("<strong>","").gsub("</strong>","").squeeze(" ").strip,
            "date_scraped" => Date.today.to_s
          }

          MasterviewScraper.save(record)
        end
      end

      def self.scrape_and_save
        url = MasterviewScraper.url_with_period(
          "http://wsconline.wyong.nsw.gov.au/applicationtracking/modules/applicationmaster",
          "thisweek",
          "4a" => "437",
          "5" => "T"
        )

        agent = Mechanize.new

        page = agent.get(url)
        Pages::TermsAndConditions.click_agree(page)

        # Doesn't redirect
        page = agent.get(url)

        # TODO: Handle paging. Currently ignores it
        scrape_page(page)
      end
    end
  end
end
