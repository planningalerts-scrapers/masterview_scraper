# frozen_string_literal: true

require "scraperwiki"
require "mechanize"

module MasterviewScraper
  module Authorities
    # Scraper for Fairfield
    module Fairfield
      # Implement a click on a link that understands stupid asp.net doPostBack
      def self.click(page, doc)
        js = doc["href"] || doc["onclick"]
        if js =~ /javascript:__doPostBack\('(.*)','(.*)'\)/
          event_target = Regexp.last_match(1)
          event_argument = Regexp.last_match(2)
          form = page.form_with(id: "aspnetForm")
          form["__EVENTTARGET"] = event_target
          form["__EVENTARGUMENT"] = event_argument
          form.submit
        elsif js =~ /return false;__doPostBack\('(.*)','(.*)'\)/
          nil
        else
          # TODO: Just follow the link likes it's a normal link
          raise
        end
      end

      def self.scrape_page(page)
        page.search("tr.rgRow,tr.rgAltRow").each do |tr|
          tds = tr.search("td").map { |t| t.inner_html.gsub("\r\n", "").strip }
          day, month, year = tds[2].split("/").map(&:to_i)
          record = {
            "info_url" => (page.uri + tr.search("td").at("a")["href"]).to_s,
            "council_reference" => tds[1],
            "date_received" => Date.new(year, month, day).to_s,
            "description" => tds[3].gsub("&amp;", "&").split("<br>")[1].to_s.squeeze(" ").strip,
            "address" => tds[3].gsub("&amp;", "&")
                               .split("<br>")[0]
                               .gsub("\r", " ")
                               .gsub("<strong>", "")
                               .gsub("</strong>", "")
                               .squeeze(" ").strip,
            "date_scraped" => Date.today.to_s
          }

          MasterviewScraper.save(record)
        end
      end

      def self.url
        from = (Date.today - 14).strftime("%d/%m/%Y")
        to = Date.today.strftime("%d/%m/%Y")
        "https://openaccess.fairfieldcity.nsw.gov.au/OpenAccess/Modules/Applicationmaster/"\
          "default.aspx?page=found&1=#{from}&2=#{to}&4a=10&6=F"
      end

      def self.scrape_and_save
        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)

        MasterviewScraper::Pages::TermsAndConditions.click_agree(page)

        page = agent.get(url)

        current_page_no = 1

        while page
          puts "Scraping page #{current_page_no}..."
          scrape_page(page)

          current_page_no += 1

          next_page_link = page.at(".rgPageNext")
          page = (click(page, next_page_link) if next_page_link)
        end
      end
    end
  end
end
