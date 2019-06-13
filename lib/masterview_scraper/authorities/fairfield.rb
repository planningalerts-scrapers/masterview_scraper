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

          puts "Saving record " + record["council_reference"] + " - " + record["address"]
          ScraperWiki.save_sqlite(["council_reference"], record)
        end
      end

      def self.scrape_and_save
        url = "https://openaccess.fairfieldcity.nsw.gov.au/OpenAccess/Modules/Applicationmaster/"\
              "default.aspx?page=found&1=thisweek&4a=10&6=F"

        agent = Mechanize.new

        # Read in a page
        page = agent.get(url)

        # This is weird. There are two forms with the Agree / Disagree buttons. One of them
        # works the other one doesn't. Go figure.
        form = page.forms[0]
        button = form.button_with(value: "Agree")
        raise "Can't find agree button" if button.nil?

        form.submit(button)

        page = agent.get(url)

        current_page_no = 1
        next_page_link = true

        while next_page_link
          puts "Scraping page #{current_page_no}..."
          scrape_page(page)

          current_page_no += 1
          next_page_link = page.at(".rgPageNext")

          unless next_page_link.nil?
            page = click(page, next_page_link)
            next_page_link = nil if page.nil?
          end
        end
      end
    end
  end
end
