# frozen_string_literal: true

require "timecop"

RSpec.describe MasterviewScraper do
  it "has a version number" do
    expect(MasterviewScraper::VERSION).not_to be nil
  end

  describe ".scrape_and_save" do
    def test_scrape_and_save(authority)
      File.delete("./data.sqlite") if File.exist?("./data.sqlite")

      VCR.use_cassette(authority) do
        Timecop.freeze(Date.new(2019, 5, 14)) do
          MasterviewScraper.scrape_and_save(authority)
        end
      end

      expected = if File.exist?("spec/expected/#{authority}.yml")
                   YAML.safe_load(File.read("spec/expected/#{authority}.yml"))
                 else
                   []
                 end
      results = ScraperWiki.select("* from data order by council_reference")

      ScraperWiki.close_sqlite

      if results != expected
        # Overwrite expected so that we can compare with version control
        # (and maybe commit if it is correct)
        File.open("spec/expected/#{authority}.yml", "w") do |f|
          f.write(results.to_yaml)
        end
      end

      expect(results).to eq expected
    end

    AUTHORITIES = %i[
      wingecarribee hurstville bundaberg bellingen wyong toowoomba shoalhaven moreton_bay
      marion mackay logan lake_macquarie ipswich hawkesbury fraser_coast fairfield brisbane
    ].freeze

    AUTHORITIES.each do |authority|
      it authority do
        test_scrape_and_save(authority)
      end
    end
  end
end
