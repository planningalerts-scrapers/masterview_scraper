# frozen_string_literal: true

require "scraperwiki"
require "mechanize"

module MasterviewScraper
  module Authorities
    # Scraper for Fairfield
    module Fairfield
      # Implement a click on a link that understands stupid asp.net doPostBack
      def self.click(doc, page)
        if doc["onclick"] =~ /javascript:__doPostBack\('(.*)','(.*)'\)/
          form = page.form_with(id: "aspnetForm")
          form["__EVENTTARGET"] = Regexp.last_match(1)
          form["__EVENTARGUMENT"] = Regexp.last_match(2)
          form.submit
        elsif doc["onclick"] =~ /return false;__doPostBack\('(.*)','(.*)'\)/
          nil
        else
          # TODO: Just follow the link likes it's a normal link
          raise
        end
      end

      def self.scrape_index_page(page)
        table = page.at("table")
        data = Table.extract_table(table)
        data.each do |row|
          record = {
            "info_url" => (page.uri + row[:url]).to_s,
            "council_reference" => row[:content]["Number"],
            "date_received" => Date.strptime(row[:content]["Submitted"], "%d/%m/%Y").to_s,
            # TODO: Do proper html entity conversion
            "description" => row[:content]["Details"].split("<br>")[1].gsub("&amp;", "&"),
            "address" => row[:content]["Details"].split("<br>")[0],
            "date_scraped" => Date.today.to_s
          }

          yield record
        end
      end

      def self.url
        from = (Date.today - 14).strftime("%d/%m/%Y")
        to = Date.today.strftime("%d/%m/%Y")
        "https://openaccess.fairfieldcity.nsw.gov.au/OpenAccess/Modules/Applicationmaster/"\
          "default.aspx?page=found&1=#{from}&2=#{to}&4a=10&6=F"
      end

      def self.next_index_page(page)
        link = page.at(".rgPageNext")
        return if link.nil?

        click(link, page)
      end

      def self.scrape
        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)
        MasterviewScraper::Pages::TermsAndConditions.click_agree(page)

        page = agent.get(url)

        while page
          scrape_index_page(page) do |record|
            yield record
          end
          page = next_index_page(page)
        end
      end

      def self.scrape_and_save
        scrape do |record|
          MasterviewScraper.save(record)
        end
      end
    end
  end
end
