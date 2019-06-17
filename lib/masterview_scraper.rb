# frozen_string_literal: true

require "masterview_scraper/version"
require "masterview_scraper/authorities/bellingen"
require "masterview_scraper/authorities/brisbane"
require "masterview_scraper/authorities/fraser_coast"
require "masterview_scraper/authorities/hawkesbury"
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
      scrape(
        url_last_14_days(
          "https://openaccess.fairfieldcity.nsw.gov.au/OpenAccess/Modules/Applicationmaster",
          "4a" => 10
        )
      ) { |record| save(record) }
    elsif authority == :fraser_coast
      Authorities::FraserCoast.scrape_and_save
    elsif authority == :hawkesbury
      Authorities::Hawkesbury.scrape_and_save
    else
      raise "Unexpected authority: #{authority}"
    end
  end

  def self.scrape(url)
    agent = Mechanize.new

    # Read in a page
    page = agent.get(url)
    Pages::TermsAndConditions.click_agree(page)

    page = agent.get(url)

    while page
      Pages::Index.scrape(page) do |record|
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
      { "page" => "found", "6" => "F" }.merge(params)
    )
  end

  def self.url_last_14_days(base_url, params = {})
    url_date_range(base_url, Date.today - 14, Date.today, params)
  end
end
