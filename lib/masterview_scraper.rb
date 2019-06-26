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
  def self.scrape(authority)
    raise "Unexpected authority: #{authority}" unless AUTHORITIES.key?(authority)

    scrape_period(AUTHORITIES[authority]) do |record|
      yield record
    end
  end

  def self.scrape_and_save(authority)
    scrape(authority) do |record|
      save(record)
    end
  end

  def self.scrape_period(
    url:,
    period:,
    params: {},
    state: nil,
    use_api: false,
    disable_ssl_certificate_check: false,
    long_council_reference: false,
    types: nil,
    proxy: false,
    # page_size only applies when use_api is true at the moment
    page_size: 100
  )
    if use_api
      scrape_api_period(
        url,
        period,
        disable_ssl_certificate_check,
        long_council_reference,
        types,
        proxy,
        page_size
      ) do |record|
        yield record
      end
    else
      scrape_url(
        url_with_period(url, period, params), state, disable_ssl_certificate_check, proxy
      ) do |record|
        yield record
      end
    end
  end

  def self.scrape_api_period(
    url, period, disable_ssl_certificate_check, long_council_reference, types,
    proxy, page_size = 100
  )
    if period == :last10days
      scrape_api(
        url,
        Date.today - 10,
        Date.today,
        disable_ssl_certificate_check,
        long_council_reference,
        types,
        proxy,
        page_size
      ) do |record|
        yield record
      end
    elsif period == :last30days
      scrape_api(
        url,
        Date.today - 30,
        Date.today,
        disable_ssl_certificate_check,
        long_council_reference,
        types,
        proxy,
        page_size
      ) do |record|
        yield record
      end
    elsif period == :thismonth
      today = Date.today
      start_of_this_month = Date.new(today.year, today.month, 1)
      scrape_api(
        url,
        start_of_this_month,
        today,
        disable_ssl_certificate_check,
        long_council_reference,
        types,
        proxy,
        page_size
      ) do |record|
        yield record
      end
    else
      raise "Unexpected period: #{period}"
    end
  end

  def self.scrape_api(
    url,
    start_date,
    end_date,
    disable_ssl_certificate_check,
    long_council_reference,
    types,
    proxy,
    page_size = 100
  )
    agent = Mechanize.new
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE if disable_ssl_certificate_check
    agent.set_proxy(ENV["MORPH_PROXY_HOST"], ENV["MORPH_PROXY_PORT"].to_i) if proxy

    page = agent.get(url + "/")

    MasterviewScraper::Pages::TermsAndConditions.click_agree(page)

    GetApplicationsApi.scrape(
      url: url, start_date: start_date, end_date: end_date,
      agent: agent, long_council_reference: long_council_reference, types: types,
      page_size: page_size
    ) do |record|
      yield record
    end
  end

  # Set state if the address does not already include the state (e.g. NSW, WA, etc..)
  def self.scrape_url(url, state = nil, disable_ssl_certificate_check = false, proxy = false)
    agent = Mechanize.new
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE if disable_ssl_certificate_check
    agent.set_proxy(ENV["MORPH_PROXY_HOST"], ENV["MORPH_PROXY_PORT"].to_i) if proxy

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
