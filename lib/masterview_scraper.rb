# frozen_string_literal: true

require "masterview_scraper/version"
require "masterview_scraper/authorities/bellingen"
require "masterview_scraper/authorities/shoalhaven"
require "masterview_scraper/pages/index"
require "masterview_scraper/pages/terms_and_conditions"
require "masterview_scraper/table"

require "scraperwiki"
require "mechanize"

# Scrape a masterview development application system
module MasterviewScraper
  def self.scrape_and_save(authority)
    if authority == :bellingen
      Authorities::Bellingen.scrape_and_save
    elsif authority == :brisbane
      MasterviewScraper.scrape_and_save_last_14_days(
        url: "https://pdonline.brisbane.qld.gov.au/MasterViewUI/Modules/ApplicationMaster",
        params: { "6" => "F" }
      )
    elsif authority == :fairfield
      scrape_and_save_last_14_days(
        url: "https://openaccess.fairfieldcity.nsw.gov.au/OpenAccess/Modules/Applicationmaster",
        params: { "4a" => 10, "6" => "F" }
      )
    elsif authority == :fraser_coast
      scrape_and_save_last_14_days(
        url: "https://pdonline.frasercoast.qld.gov.au/Modules/ApplicationMaster",
        params: {
          # TODO: Do the encoding automatically
          "4a" => "BPS%27,%27MC%27,%27OP%27,%27SB%27,%27MCU%27,%27ROL%27,%27OPWKS%27,"\
                "%27QMCU%27,%27QRAL%27,%27QOPW%27,%27QDBW%27,%27QPOS%27,%27QSPS%27,"\
                "%27QEXE%27,%27QCAR%27,%27ACA",
          "6" => "F"
        },
        state: "QLD"
      )
    elsif authority == :hawkesbury
      scrape_and_save_last_14_days(
        url: "http://council.hawkesbury.nsw.gov.au/MasterviewUI/Modules/applicationmaster",
        params: { "4a" => "DA", "6" => "F" },
        state: "NSW"
      )
    elsif authority == :ipswich
      scrape_and_save_last_14_days(
        url: "http://pdonline.ipswich.qld.gov.au/pdonline/modules/applicationmaster",
        # TODO: Don't know what this parameter "5" does
        params: { "5" => "T", "6" => "F" }
      )
    elsif authority == :lake_macquarie
      scrape_and_save_url(
        url_with_period(
          "http://apptracking.lakemac.com.au/modules/ApplicationMaster",
          "thisweek",
          "4a" => "437",
          "5" => "T"
        )
      )
    elsif authority == :logan
      scrape_and_save_last_14_days(
        url: "http://pdonline.logan.qld.gov.au/MasterViewUI/Modules/ApplicationMaster",
        params: { "6" => "F" }
      )
    elsif authority == :mackay
      scrape_and_save_last_30_days(
        url: "https://planning.mackay.qld.gov.au/masterview/Modules/Applicationmaster",
        params: {
          "4a" => "443,444,445,446,487,555,556,557,558,559,560,564",
          "6" => "F"
        }
      )
    elsif authority == :marion
      scrape_and_save_url(
        url_with_period(
          "http://ecouncil.marion.sa.gov.au/datrackingui/modules/applicationmaster",
          "thisweek",
          "4a" => "7",
          "6" => "F"
        )
      )
    elsif authority == :moreton_bay
      scrape_and_save_url(
        url_with_period(
          "http://pdonline.moretonbay.qld.gov.au/Modules/applicationmaster",
          "thismonth",
          "6" => "F"
        )
      )
    elsif authority == :shoalhaven
      Authorities::Shoalhaven.scrape_and_save
    elsif authority == :toowoomba
      scrape_and_save_last_30_days(
        url: "https://pdonline.toowoombarc.qld.gov.au/Masterview/Modules/ApplicationMaster",
        params: {
          "4a" => "\'488\',\'487\',\'486\',\'495\',\'521\',\'540\',\'496\',\'562\'",
          "6" => "F"
        }
      )
    elsif authority == :wyong
      scrape_and_save_last_30_days(
        url: "http://wsconline.wyong.nsw.gov.au/applicationtracking/modules/applicationmaster",
        params: {
          "4a" => "437",
          "5" => "T"
        }
      )
    else
      raise "Unexpected authority: #{authority}"
    end
  end

  def self.scrape_and_save_last_14_days(url:, params:, state: nil)
    scrape_and_save_url(url_last_14_days(url, params), state)
  end

  def self.scrape_and_save_last_30_days(url:, params:, state: nil)
    scrape_and_save_url(url_last_30_days(url, params), state)
  end

  def self.scrape_and_save_url(url, state = nil)
    scrape(url, state) { |record| save(record) }
  end

  # Set state if the address does not already include the state (e.g. NSW, WA, etc..)
  def self.scrape(url, state = nil)
    agent = Mechanize.new

    # Read in a page
    page = agent.get(url)

    if Pages::TermsAndConditions.on_page?(page)
      Pages::TermsAndConditions.click_agree(page)

      # Some (but not all) sites do not redirect back to the original
      # requested url after the terms and conditions page. So,
      # let's just request it again
      page = agent.get(url)
    end

    while page
      Pages::Index.scrape(page) do |record|
        record["address"] += ", " + state if state
        yield record
      end
      page = Pages::Index.next(page)
    end
  end

  def self.log(record)
    puts "Saving record " + record["council_reference"] + " - " + record["address"]
  end

  def self.save(record)
    log(record)
    ScraperWiki.save_sqlite(["council_reference"], record)
  end

  def self.url_date_range(base_url, from, to, params)
    url_with_default_params(
      base_url,
      { "1" => from.strftime("%d/%m/%Y"), "2" => to.strftime("%d/%m/%Y") }.merge(params)
    )
  end

  def self.url_with_period(base_url, period, params)
    MasterviewScraper.url_with_default_params(
      base_url,
      { "1" => period }.merge(params)
    )
  end

  # TODO: Escape params by using activesupport .to_query
  def self.url_with_params(base_url, params)
    base_url + "/default.aspx?" + params.map { |k, v| "#{k}=#{v}" }.join("&")
  end

  def self.url_with_default_params(base_url, params)
    url_with_params(
      base_url,
      { "page" => "found" }.merge(params)
    )
  end

  def self.url_last_n_days(base_url, days, params = {})
    url_date_range(base_url, Date.today - days, Date.today, params)
  end

  def self.url_last_14_days(base_url, params = {})
    url_last_n_days(base_url, 14, params)
  end

  def self.url_last_30_days(base_url, params = {})
    url_last_n_days(base_url, 30, params)
  end
end
