# frozen_string_literal: true

require "masterview_scraper/version"
require "masterview_scraper/authorities/shoalhaven"
require "masterview_scraper/pages/detail"
require "masterview_scraper/pages/index"
require "masterview_scraper/pages/terms_and_conditions"
require "masterview_scraper/table"

require "scraperwiki"
require "mechanize"

# Scrape a masterview development application system
module MasterviewScraper
  AUTHORITIES = {
    bellingen: {
      url: "http://infomaster.bellingen.nsw.gov.au/MasterViewLive/modules/applicationmaster",
      period: :thismonth,
      params: {
        "4a" => "DA,CDC,TA,MD",
        "6" => "F"
      }
    },
    brisbane: {
      url: "https://pdonline.brisbane.qld.gov.au/MasterViewUI/Modules/ApplicationMaster",
      period: :last14days,
      params: { "6" => "F" }
    },
    fairfield: {
      url: "https://openaccess.fairfieldcity.nsw.gov.au/OpenAccess/Modules/Applicationmaster",
      period: :last14days,
      params: { "4a" => 10, "6" => "F" }
    },
    fraser_coast: {
      url: "https://pdonline.frasercoast.qld.gov.au/Modules/ApplicationMaster",
      period: :last14days,
      params: {
        # TODO: Do the encoding automatically
        "4a" => "BPS%27,%27MC%27,%27OP%27,%27SB%27,%27MCU%27,%27ROL%27,%27OPWKS%27,"\
              "%27QMCU%27,%27QRAL%27,%27QOPW%27,%27QDBW%27,%27QPOS%27,%27QSPS%27,"\
              "%27QEXE%27,%27QCAR%27,%27ACA",
        "6" => "F"
      },
      state: "QLD"
    },
    hawkesbury: {
      url: "http://council.hawkesbury.nsw.gov.au/MasterviewUI/Modules/applicationmaster",
      period: :last14days,
      params: { "4a" => "DA", "6" => "F" },
      state: "NSW"
    },
    ipswich: {
      url: "http://pdonline.ipswich.qld.gov.au/pdonline/modules/applicationmaster",
      period: :last14days,
      # TODO: Don't know what this parameter "5" does
      params: { "5" => "T", "6" => "F" }
    },
    lake_macquarie: {
      url: "http://apptracking.lakemac.com.au/modules/ApplicationMaster",
      period: :thisweek,
      params: {
        "4a" => "437",
        "5" => "T"
      }
    },
    logan: {
      url: "http://pdonline.logan.qld.gov.au/MasterViewUI/Modules/ApplicationMaster",
      period: :last14days,
      params: { "6" => "F" }
    },
    mackay: {
      url: "https://planning.mackay.qld.gov.au/masterview/Modules/Applicationmaster",
      period: :last30days,
      params: {
        "4a" => "443,444,445,446,487,555,556,557,558,559,560,564",
        "6" => "F"
      }
    },
    marion: {
      url: "http://ecouncil.marion.sa.gov.au/datrackingui/modules/applicationmaster",
      period: :thisweek,
      params: {
        "4a" => "7",
        "6" => "F"
      }
    },
    moreton_bay: {
      url: "http://pdonline.moretonbay.qld.gov.au/Modules/applicationmaster",
      period: :thismonth,
      params: {
        "6" => "F"
      }
    },
    toowoomba: {
      url: "https://pdonline.toowoombarc.qld.gov.au/Masterview/Modules/ApplicationMaster",
      period: :last30days,
      params: {
        "4a" => "\'488\',\'487\',\'486\',\'495\',\'521\',\'540\',\'496\',\'562\'",
        "6" => "F"
      }
    },
    wyong: {
      url: "http://wsconline.wyong.nsw.gov.au/applicationtracking/modules/applicationmaster",
      period: :last30days,
      params: {
        "4a" => "437",
        "5" => "T"
      }
    }
  }.freeze

  def self.scrape_and_save(authority)
    if AUTHORITIES[authority]
      scrape_and_save_period(AUTHORITIES[authority])
    elsif authority == :shoalhaven
      Authorities::Shoalhaven.scrape_and_save
    else
      raise "Unexpected authority: #{authority}"
    end
  end

  def self.scrape_and_save_period(url:, period:, params:, state: nil)
    scrape(url_with_period(url, period, params), state) do |record|
      save(record)
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

          info_page = agent.get(record[:info_url])
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
