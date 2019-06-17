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

          #pp record
          ScraperWiki.save_sqlite(['council_reference'], record)
        end
      end

      def self.click(nextButton, doc)
        return if nextButton['onclick'] =~ /return false/

        form = doc.forms.first

        # The joy of dealing with ASP.NET
        form['__EVENTTARGET'] = nextButton['name']
        form['__EVENTARGUMENT'] = ''
        # It doesn't seem to work without these stupid values being set.
        # Would be good to figure out where precisely in the javascript these values are coming from.
        form['ctl00%24RadScriptManager1']=
          'ctl00%24cphContent%24ctl00%24ctl00%24cphContent%24ctl00%24Radajaxpanel2Panel%7Cctl00%24cphContent%24ctl00%24ctl00%24RadGrid1%24ctl00%24ctl03%24ctl01%24ctl10'
        form['ctl00_RadScriptManager1_HiddenField']=
          '%3B%3BSystem.Web.Extensions%2C%20Version%3D3.5.0.0%2C%20Culture%3Dneutral%2C%20PublicKeyToken%3D31bf3856ad364e35%3Aen-US%3A0d787d5c-3903-4814-ad72-296cea810318%3Aea597d4b%3Ab25378d2%3BTelerik.Web.UI%2C%20Version%3D2009.1.527.35%2C%20Culture%3Dneutral%2C%20PublicKeyToken%3D121fae78165ba3d4%3Aen-US%3A1e3fef00-f492-4ed8-96ce-6371bc241e1c%3A16e4e7cd%3Af7645509%3A24ee1bba%3Ae330518b%3A1e771326%3Ac8618e41%3A4cacbc31%3A8e6f0d33%3Aed16cbdc%3A58366029%3Aaa288e2d'
        form.submit(form.button_with(:name => nextButton['name']))
      end

      def self.next_page(doc)
        nextButton = doc.at('.rgPageNext')
        return if nextButton.nil?

        click(nextButton, doc)
      end

      def self.scrape_and_follow_next_link(doc)
        scrape_table(doc)
        doc = next_page(doc)
        scrape_and_follow_next_link(doc) if doc
      end

      def self.url
        'http://council.hawkesbury.nsw.gov.au/MasterviewUI/Modules/applicationmaster/default.aspx?page=found&1=thismonth&4a=DA&6=F'
      end

      def self.scrape_and_save
        agent = Mechanize.new

        # Jump through bollocks agree screen
        doc = agent.get(url)
        Pages::TermsAndConditions.click_agree(doc)

        doc = agent.get(url)

        scrape_and_follow_next_link(doc)
      end
    end
  end
end
