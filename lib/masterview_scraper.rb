# frozen_string_literal: true

require "masterview_scraper/version"
require "masterview_scraper/authorities/bellingen"
require "masterview_scraper/authorities/brisbane"
require "masterview_scraper/authorities/fairfield"
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
      Authorities::Fairfield.scrape_and_save
    elsif authority == :fraser_coast
      Authorities::FraserCoast.scrape_and_save
    elsif authority == :hawkesbury
      Authorities::Hawkesbury.scrape_and_save
    else
      raise "Unexpected authority: #{authority}"
    end
  end

  def self.log(record)
    puts "Saving record " + record["council_reference"] + " - " + record["address"]
  end

  def self.save(record)
    log(record)
    ScraperWiki.save_sqlite(["council_reference"], record)
  end

  def self.url_date_range(base_url, from, to, extra_params)
    params = {
      "1" => from.strftime("%d/%m/%Y"),
      "2" => to.strftime("%d/%m/%Y")
    }
    url_with_params(base_url, params.merge(extra_params))
  end

  def self.url_with_period(base_url, period, extra_params)
    params = { "1" => period }
    MasterviewScraper.url_with_params(base_url, params.merge(extra_params))
  end

  # TODO: Escape params by using activesupport .to_query
  def self.url_with_params(base_url, params)
    base_url + "/default.aspx?" + params.map { |k, v| "#{k}=#{v}" }.join("&")
  end

  def self.url_last_14_days(base_url, extra_params)
    url_date_range(base_url, Date.today - 14, Date.today, extra_params)
  end
end
