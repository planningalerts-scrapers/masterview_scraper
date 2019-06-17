require 'scraperwiki'
require 'rubygems'
require 'mechanize'

module MasterviewScraper
  module Authorities
    module Hawkesbury
      def self.clean_whitespace(a)
        a.gsub("\r", ' ').gsub("\n", ' ').squeeze(" ").strip
      end

      def self.scrape_table(doc)
        doc.search('table tbody tr').each do |tr|
          # Columns in table
          # Show  Number  Submitted  Details
          tds = tr.search('td')
          h = tds.map{|td| td.inner_html}

          record = {
            'info_url' => (doc.uri + tds[0].at('a')['href']).to_s,
            'council_reference' => clean_whitespace(h[1]),
            'date_received' => Date.strptime(clean_whitespace(h[2]), '%d/%m/%Y').to_s,
            'address' => (clean_whitespace(tds.search(:strong).inner_text) + ", NSW"),
            'description' => CGI::unescapeHTML(clean_whitespace(h[3].split('<br>')[1..-1].join)),
            'date_scraped' => Date.today.to_s
          }

          MasterviewScraper.save(record)
        end
      end

      def self.url
        MasterviewScraper.url_last_14_days(
          "http://council.hawkesbury.nsw.gov.au/MasterviewUI/Modules/applicationmaster",
          "4a" => "DA"
        )
      end

      def self.scrape_and_save
        agent = Mechanize.new

        # Jump through bollocks agree screen
        doc = agent.get(url)
        Pages::TermsAndConditions.click_agree(doc)

        doc = agent.get(url)

        while doc
          scrape_table(doc)
          doc = Pages::Index.next(doc)
        end
      end
    end
  end
end
