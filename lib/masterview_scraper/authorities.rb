# frozen_string_literal: true

module MasterviewScraper
  AUTHORITIES = {
    bellingen: {
      url: "http://infomaster.bellingen.nsw.gov.au/MasterViewLive/modules/applicationmaster",
      period: :last30days,
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
    },
    shoalhaven: {
      url: "http://www3.shoalhaven.nsw.gov.au/masterviewUI/modules/ApplicationMaster",
      period: :thismonth,
      params: {
        "4a" => "25,13,72,60,58,56",
        "6" => "F"
      },
      state: "NSW"
    },
    bundaberg: {
      url: "https://da.bundaberg.qld.gov.au/modules/applicationmaster",
      period: :last30days,
      params: {
        "4a" => "333,322,321,324,323,325,521,522,523,524,525,526,527,528,532",
        "6" => "F"
      },
      state: "QLD"
    },
    hurstville: {
      url: "http://daenquiry.hurstville.nsw.gov.au/masterviewui/Modules/applicationmaster",
      period: :last30days,
      params: {
        "4a" => "DA%27,%27S96Mods%27,%27Mods%27,%27Reviews",
        "6" => "F"
      },
      state: "NSW"
    },
    wingecarribee: {
      url: "https://datracker.wsc.nsw.gov.au/Modules/applicationmaster",
      period: :last30days,
      params: {
        "4a" => "WLUA,82AReview,CDC,DA,Mods",
        "6" => "F"
      }
    },
    albury: {
      url: "https://eservice.alburycity.nsw.gov.au/ApplicationTracker",
      period: :last10days,
      use_api: true
    },
    bogan: {
      url: "http://datracker.bogan.nsw.gov.au:81",
      period: :last30days,
      use_api: true
    },
    cessnock: {
      url: "http://datracker.cessnock.nsw.gov.au",
      period: :last10days,
      use_api: true
    },
    griffith: {
      url: "https://datracking.griffith.nsw.gov.au",
      period: :last10days,
      use_api: true,
      # Has an incomplete certificate chain. See https://www.ssllabs.com/ssltest/analyze.html?d=datracking.griffith.nsw.gov.au
      disable_ssl_certificate_check: true
    },
    lismore: {
      url: "http://tracker.lismore.nsw.gov.au",
      period: :last30days,
      use_api: true
    },
    port_macquarie_hastings: {
      url: "https://datracker.pmhc.nsw.gov.au",
      period: :last30days,
      use_api: true
    },
    port_stephens: {
      url: "http://datracker.portstephens.nsw.gov.au",
      period: :thismonth,
      use_api: true,
      long_council_reference: true,
      types: [16, 9, 25]
    },
    singleton: {
      url: "https://datracker.singleton.nsw.gov.au:444",
      use_api: true,
      period: :last30days
    },
    byron: {
      url: "https://datracker.byron.nsw.gov.au/MasterViewUI-External",
      use_api: true,
      period: :last30days,
      page_size: 10
    }
  }.freeze
end
