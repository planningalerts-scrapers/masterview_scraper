# frozen_string_literal: true

require "masterview_scraper/version"
require "masterview_scraper/pages/detail"
require "masterview_scraper/pages/index"
require "masterview_scraper/pages/terms_and_conditions"
require "masterview_scraper/table"
require "masterview_scraper/authorities"
require "masterview_scraper/get_applications_api"

require "scraperwiki"
require "mechanize"

# Scrape a masterview development application system
module MasterviewScraper
  def self.scrape_and_save(authority)
    if AUTHORITIES.key?(authority)
      scrape_and_save_period(AUTHORITIES[authority])
    elsif authority == :albury
      MasterviewScraper.scrape_api(
        "https://eservice.alburycity.nsw.gov.au/ApplicationTracker",
        Date.today - 10,
        Date.today
      ) do |record|
        MasterviewScraper.save(record)
      end
    elsif authority == :bogan
      MasterviewScraper.scrape_api(
        "http://datracker.bogan.nsw.gov.au:81",
        Date.today - 30,
        Date.today
      ) do |record|
        MasterviewScraper.save(record)
      end
    else
      raise "Unexpected authority: #{authority}"
    end
  end

  def self.scrape_and_save_period(url:, period:, params:, state: nil)
    scrape(url_with_period(url, period, params), state) do |record|
      save(record)
    end
  end

  def self.scrape_api(url, start_date, end_date)
    agent = Mechanize.new

    page = agent.get(url + "/")

    MasterviewScraper::Pages::TermsAndConditions.click_agree(page)

    GetApplicationsApi.scrape(url, start_date, end_date, agent) do |record|
      MasterviewScraper.save(record)
    end
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
        # If index page doesn't have enough information then we need
        # to scrape the detail page
        if record[:info_url].nil? ||
           record[:council_reference].nil? ||
           record[:date_received].nil? ||
           record[:description].nil? ||
           record[:address].nil?

          begin
            info_page = agent.get(record[:info_url])
          # Doing this for the benefit of bellingen that
          # appears to be able to fault on detail pages of particular
          # applications
          rescue Mechanize::ResponseCodeError
            puts "WARNING: Skipping application because of server problem"
            next
          end
          record = Pages::Detail.scrape(info_page)
        end

        record[:address] += ", " + state if state

        yield(
          "info_url" => record[:info_url],
          "council_reference" => record[:council_reference],
          "date_received" => record[:date_received],
          "description" => record[:description],
          "address" => record[:address],
          "date_scraped" => Date.today.to_s
        )
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
    if period == :thismonth
      MasterviewScraper.url_with_default_params(
        base_url,
        { "1" => "thismonth" }.merge(params)
      )
    elsif period == :thisweek
      MasterviewScraper.url_with_default_params(
        base_url,
        { "1" => "thisweek" }.merge(params)
      )
    elsif period == :last14days
      url_last_n_days(base_url, 14, params)
    elsif period == :last30days
      url_last_n_days(base_url, 30, params)
    else
      raise "Unexpected period #{period}"
    end
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
end
