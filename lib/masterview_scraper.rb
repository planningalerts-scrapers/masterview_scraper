# frozen_string_literal: true

require "masterview_scraper/version"
require "masterview_scraper/authorities/bellingen"
require "masterview_scraper/authorities/brisbane"
require "masterview_scraper/authorities/lake_macquarie"
require "masterview_scraper/authorities/logan"
require "masterview_scraper/authorities/mackay"
require "masterview_scraper/pages/index"
require "masterview_scraper/pages/terms_and_conditions"

require "scraperwiki"
require "mechanize"

# Scrape a masterview development application system
module MasterviewScraper
  def self.scrape_and_save(authority)
    if authority == :bellingen
      Authorities::Bellingen.scrape_and_save
    elsif authority == :brisbane
      Authorities::Brisbane.scrape_and_save
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
      Authorities::LakeMacquarie.scrape_and_save
    elsif authority == :logan
      Authorities::Logan.scrape_and_save
    elsif authority == :mackay
      Authorities::Mackay.scrape_and_save
    else
      raise "Unexpected authority: #{authority}"
    end
  end

  def self.scrape_and_save_last_14_days(url:, params:, state: nil)
    scrape_and_save_url(url_last_14_days(url, params), state)
  end

  def self.scrape_and_save_url(url, state = nil)
    scrape(url, state) { |record| save(record) }
  end

  # Set state if the address does not already include the state (e.g. NSW, WA, etc..)
  def self.scrape(url, state = nil)
    agent = Mechanize.new

    # Read in a page
    page = agent.get(url)
    Pages::TermsAndConditions.click_agree(page)

    page = agent.get(url)

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

  def self.url_last_14_days(base_url, params = {})
    url_date_range(base_url, Date.today - 14, Date.today, params)
  end
end
