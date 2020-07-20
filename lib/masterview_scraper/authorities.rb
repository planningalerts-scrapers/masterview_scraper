# frozen_string_literal: true

module MasterviewScraper
  AUTHORITIES = {
    forbes: {
      url: "http://planning.forbes.nsw.gov.au",
      use_api: true,
      force_detail: true
    },
    gunnedah: {
      url: "http://datracking.gunnedah.nsw.gov.au",
      use_api: true,
      force_detail: true
    },
    maranoa: {
      url: "http://pdonline.maranoa.qld.gov.au",
      use_api: true,
      force_detail: true
    },
    moree_plains: {
      url: "http://masterview.mpsc.nsw.gov.au",
      use_api: true,
      force_detail: true
    },
    broken_hill: {
      url: "http://datracker.brokenhill.nsw.gov.au",
      use_api: true
    },
    gympie: {
      url: "https://daonline.gympie.qld.gov.au",
      use_api: true,
      force_detail: true
    },
    gladstone: {
      url: "http://masterview.gladstonerc.qld.gov.au/Modules/ApplicationMaster",
      params: {
        "4" => "DevelopApp",
        "6" => "F"
      },
      force_detail: true,
      timeout: 120
    },
    bellingen: {
      url: "http://infomaster.bellingen.nsw.gov.au/MasterViewLive/modules/applicationmaster",
      params: {
        "4a" => "DA,CDC,TA,MD",
        "6" => "F"
      },
      force_detail: true
    },
    brisbane: {
      url: "https://pdonline.brisbane.qld.gov.au/MasterViewUI/Modules/ApplicationMaster",
      params: { "6" => "F" },
      force_detail: true
    },
    fairfield: {
      url: "https://openaccess.fairfieldcity.nsw.gov.au/OpenAccess/Modules/Applicationmaster",
      params: { "4a" => 10, "6" => "F" },
      force_detail: true
    },
    fraser_coast: {
      url: "https://pdonline.frasercoast.qld.gov.au/Modules/ApplicationMaster",
      params: {
        # TODO: Do the encoding automatically
        "4a" => "BPS%27,%27MC%27,%27OP%27,%27SB%27,%27MCU%27,%27ROL%27,%27OPWKS%27,"\
              "%27QMCU%27,%27QRAL%27,%27QOPW%27,%27QDBW%27,%27QPOS%27,%27QSPS%27,"\
              "%27QEXE%27,%27QCAR%27,%27ACA",
        "6" => "F"
      },
      state: "QLD",
      force_detail: true
    },
    hawkesbury: {
      url: "https://council.hawkesbury.nsw.gov.au/MasterviewUI/Modules/applicationmaster",
      params: { "4a" => "DA", "6" => "F" },
      state: "NSW",
      force_detail: true
    },
    ipswich: {
      url: "http://pdonline.ipswich.qld.gov.au/pdonline/modules/applicationmaster",
      # TODO: Don't know what this parameter "5" does
      params: { "5" => "T", "6" => "F" },
      force_detail: true
    },
    logan: {
      url: "http://pdonline.logan.qld.gov.au/MasterViewUI/Modules/ApplicationMaster",
      params: { "6" => "F" },
      force_detail: true
    },
    mackay: {
      url: "https://planning.mackay.qld.gov.au/masterview/Modules/Applicationmaster",
      params: {
        "4a" => "443,444,445,446,487,555,556,557,558,559,560,564",
        "6" => "F"
      },
      force_detail: true,
      timeout: 120
    },
    marion: {
      url: "http://development.marion.sa.gov.au/MasterViewUI",
      use_api: true,
      page_size: 10,
      force_detail: true
    },
    moreton_bay: {
      url: "http://pdonline.moretonbay.qld.gov.au/Modules/applicationmaster",
      params: {
        "6" => "F"
      },
      force_detail: true
    },
    toowoomba: {
      url: "https://pdonline.toowoombarc.qld.gov.au/Masterview/Modules/ApplicationMaster",
      params: {
        "4a" => "\'488\',\'487\',\'486\',\'495\',\'521\',\'540\',\'496\',\'562\'",
        "6" => "F"
      },
      force_detail: true
    },
    wyong: {
      url: "http://wsconline.wyong.nsw.gov.au/applicationtracking/modules/applicationmaster",
      params: {
        "4a" => "437",
        "5" => "T"
      },
      force_detail: true
    },
    shoalhaven: {
      url: "http://www3.shoalhaven.nsw.gov.au/masterviewUI/modules/ApplicationMaster",
      params: {
        "4a" => "25,13,72,60,58,56",
        "6" => "F"
      },
      state: "NSW",
      force_detail: true
    },
    bundaberg: {
      url: "https://da.bundaberg.qld.gov.au/modules/applicationmaster",
      params: {
        "4a" => "333,322,321,324,323,325,521,522,523,524,525,526,527,528,532",
        "6" => "F"
      },
      state: "QLD",
      force_detail: true
    },
    wingecarribee: {
      url: "https://datracker.wsc.nsw.gov.au/Modules/applicationmaster",
      params: {
        "4a" => "WLUA,82AReview,CDC,DA,Mods",
        "6" => "F"
      },
      force_detail: true
    },
    albury: {
      url: "https://eservice.alburycity.nsw.gov.au/ApplicationTracker",
      use_api: true,
      force_detail: true
    },
    bogan: {
      url: "http://datracker.bogan.nsw.gov.au:81",
      use_api: true,
      force_detail: true
    },
    cessnock: {
      url: "http://datracker.cessnock.nsw.gov.au",
      use_api: true,
      force_detail: true
    },
    griffith: {
      url: "https://datracking.griffith.nsw.gov.au",
      use_api: true,
      # Has an incomplete certificate chain. See https://www.ssllabs.com/ssltest/analyze.html?d=datracking.griffith.nsw.gov.au
      disable_ssl_certificate_check: true,
      force_detail: true
    },
    lismore: {
      url: "http://tracker.lismore.nsw.gov.au",
      use_api: true,
      force_detail: true
    },
    port_macquarie_hastings: {
      url: "https://datracker.pmhc.nsw.gov.au",
      use_api: true,
      force_detail: true
    },
    port_stephens: {
      url: "http://datracker.portstephens.nsw.gov.au",
      use_api: true,
      long_council_reference: true,
      types: [16, 9, 25],
      force_detail: true
    },
    singleton: {
      url: "https://datracker.singleton.nsw.gov.au:444",
      use_api: true,
      force_detail: true
    },
    byron: {
      url: "https://datracker.byron.nsw.gov.au/MasterViewUI-External",
      use_api: true,
      page_size: 10,
      force_detail: true
    },
    camden: {
      url: "https://planning.camden.nsw.gov.au",
      use_api: true,
      force_detail: true,
      # There is at least one page
      # https://planning.camden.nsw.gov.au/Application/ApplicationDetails/013.2017.00001246.005
      # that takes about 80 seconds to return! So we need to increase the timeout. In fact that
      # wasn't even enough. We need 3 minutes per page. Eek!
      timeout: 180
    }
  }.freeze
end
