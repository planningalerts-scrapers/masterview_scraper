require "masterview_scraper/version"

require 'scraperwiki'
require 'mechanize'

module MasterviewScraper
  def self.scrape_and_save(authority)
    if authority == :bellingen
      scrape_and_save_bellingen
    else
      raise "Unexpected authority: #{authority}"
    end
  end

  def self.scrape_and_save_bellingen
    agent = Mechanize.new

    # All applications in the last month
    url = 'http://infomaster.bellingen.nsw.gov.au/MasterViewLive/modules/applicationmaster/default.aspx?page=found&1=thismonth&4a=DA,CDC,TA,MD&6=F'
    page = agent.get(url)

    # Click the Agree button on the form
    form = page.forms_with(:name => /frmMasterView|frmMasterPlan|frmApplicationMaster/).first
    form.submit(form.button_with(:name => /btnOk|Yes|Button1|Agree/))

    # Get the page again
    page = agent.get(url)

    # Visit each DA page so we can get the details
    (page/'//*[@id="ctl03_lblData"]').search("a").each do |a|
      begin
        info_page = agent.get(agent.page.uri + URI.parse(a.attributes['href']))
        details = (info_page/'//*[@id="lblDetails"]')

        council_reference = (info_page/'//*[@id="ctl03_lblHead"]').inner_text.split(' ')[0]
        record = {
          'council_reference' => council_reference,
          'address'           => (info_page/'//*[@id="lblLand"]').inner_text.strip.split("\n")[0].strip,
          'description'       => details.at("td").inner_text.split("\r")[1].strip[13..-1],
          'info_url'          => info_page.uri.to_s,
          'date_scraped'      => Date.today.to_s,
          'date_received'     => Date.strptime(details.at("td").inner_html.split("<br>")[1].strip[11..-1], "%d/%m/%Y").to_s
        }
      rescue Exception => e
        puts "Error getting details for development application #{a.to_s} so skipping"
        next
      end

      #    puts record
      puts "Saving record " + record['council_reference']
      ScraperWiki.save_sqlite(['council_reference'], record)
    end
  end
end
