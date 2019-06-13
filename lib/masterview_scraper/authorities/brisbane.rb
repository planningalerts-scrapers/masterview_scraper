# frozen_string_literal: true

require "scraperwiki"
require "mechanize"

module MasterviewScraper
  module Authorities
    # Scraper for Brisbane
    module Brisbane
      def self.scrape
        period = case ENV["MORPH_PERIOD"]
                 when "lastmonth"
                   "lastmonth"
                 when "thismonth"
                   "thismonth"
                 else
                   (Date.today - 14).strftime("%d/%m/%Y") + "&2=" + Date.today.strftime("%d/%m/%Y")
                 end

        puts "Collecting data from " + period
        # Scraping from Masterview 2.0

        agent = Mechanize.new

        url = "https://pdonline.brisbane.qld.gov.au/MasterViewUI/Modules/ApplicationMaster/"\
              "default.aspx?page=found&1=" + period + "&6=F"

        # Read in a page
        page = agent.get(url)

        Pages::TermsAndConditions.click_agree(page)

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

      def self.scrape_index_page(page)
        page.at("table#ctl00_cphContent_ctl01_ctl00_RadGrid1_ctl00 tbody").search("tr").each do |tr|
          tds = tr.search("td").map { |t| t.inner_text.gsub("\r\n", "").strip }

          if tds[0] == "There were no records matching your search criteria. Please try again."
            raise "Something strange here. It says no records found"
          end

          raise "Couldn't find date field" if tds[3].nil?

          day, month, year = tds[3].split("/").map(&:to_i)
          info_url = (page.uri + tr.search("td").at("a")["href"]).to_s
          record = {
            "info_url" => info_url,
            "council_reference" => tds[1].split(" - ")[0].squeeze(" ").strip,
            "date_received" => Date.new(year, month, day).to_s,
            "description" => tds[1].split(" - ")[1..-1].join(" - ").squeeze(" ").strip,
            "address" => tds[2].squeeze(" ").strip,
            "date_scraped" => Date.today.to_s
          }

          yield record
        end
      end

      # Returns the next page unless there is none in which case nil
      def self.next_index_page(page)
        next_button = page.at(".rgPageNext")
        puts "No further pages" if next_button.nil?

        return if next_button.nil? || next_button["onclick"] =~ /return false/

        form = page.forms.first

        # The joy of dealing with ASP.NET
        form["__EVENTTARGET"] = next_button["name"]
        form["__EVENTARGUMENT"] = ""
        # It doesn't seem to work without these stupid values being set.
        # Would be good to figure out where precisely in the javascript these
        # values are coming from.
        form["ctl00%24RadScriptManager1"] =
          "ctl00%24cphContent%24ctl00%24ctl00%24cphContent%24ctl00%24Radajaxpanel2Panel"\
          "%7Cctl00%24cphContent%24ctl00%24ctl00%24RadGrid1%24ctl00%24ctl03%24ctl01%24ctl10"
        form["ctl00_RadScriptManager1_HiddenField"] =
          "%3B%3BSystem.Web.Extensions%2C%20Version%3D3.5.0.0%2C%20Culture%3Dneutral"\
          "%2C%20PublicKeyToken%3D31bf3856ad364e35%3Aen-US"\
          "%3A0d787d5c-3903-4814-ad72-296cea810318%3Aea597d4b%3Ab25378d2"\
          "%3BTelerik.Web.UI%2C%20Version%3D2009.1.527.35%2C%20Culture%3Dneutral"\
          "%2C%20PublicKeyToken%3D121fae78165ba3d4%3Aen-US"\
          "%3A1e3fef00-f492-4ed8-96ce-6371bc241e1c%3A16e4e7cd%3Af7645509%3A24ee1bba"\
          "%3Ae330518b%3A1e771326%3Ac8618e41%3A4cacbc31%3A8e6f0d33%3Aed16cbdc%3A58366029%3Aaa288e2d"
        form.submit(form.button_with(name: next_button["name"]))
      end
    end
  end
end
