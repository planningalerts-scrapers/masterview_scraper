# frozen_string_literal: true

require "masterview_scraper/postback"

module MasterviewScraper
  module Pages
    # A page with a table of results of a search
    module Index
      # Handles all the variants of the column names and handles them all to
      # transform them to a standard name that we use here
      def self.normalise_name(name, value)
        case name
        when "Link", "Show", ""
          :link
        when "Application", "Number"
          :council_reference
        when "Submitted", "Date Lodged"
          :date_received
        when "Details", "Address/Details", "Description", "Property/Application Details"
          :details
        when "Determination", "Decision"
          :decision
        when "Address"
          :address
        else
          raise "Unknown name #{name} with value #{value}"
        end
      end

      def self.scrape(page)
        table = page.at("table.rgMasterTable") ||
                page.at("table table")
        Table.extract_table(table).each do |row|
          normalised = row[:content].map { |k, v| [normalise_name(k, v), v] }.to_h

          href = Nokogiri::HTML.fragment(normalised[:link]).at("a")["href"]
          if normalised[:details]
            details = scrape_details_field(normalised[:details])
            normalised[:description] = details[:description]
            normalised[:address] = details[:address]
          # For the odd one that doesn't have a details field we have some
          # special handling
          else
            v = normalised[:council_reference].split("-", 2)
            normalised[:council_reference] = v[0].strip
            normalised[:description] = v[1].strip
          end

          yield(
            "info_url" => (page.uri + href).to_s,
            "council_reference" => normalised[:council_reference].squeeze(" "),
            "date_received" => Date.strptime(normalised[:date_received], "%d/%m/%Y").to_s,
            "description" => normalised[:description],
            "address" => normalised[:address],
            # TODO: date_scraped should NOT be added here
            "date_scraped" => Date.today.to_s
          )
        end
      end

      def self.scrape_details_field(field)
        # Split out the seperate sections of the details field
        details = field.split("<br>").map do |detail|
          strip_html(detail).squeeze(" ").strip
        end
        details = details.delete_if do |detail|
          detail =~ /^Applicant : / ||
            detail =~ /^Applicant:/ ||
            detail =~ /^Status:/
        end
        details = details.map do |detail|
          if detail =~ /^Description: (.*)/
            Regexp.last_match(1)
          else
            detail
          end
        end
        if details.length < 2 || details.length > 3
          raise "Unexpected number of things in details: #{details}"
        end

        {
          description: (details.length == 3 ? details[2] : details[1]),
          address: details[0].gsub("\r", " ").gsub("\n", " ").squeeze(" ")
        }
      end

      def self.find_field(row, names)
        value = row[:content].find { |k, _v| names.include?(k) }[1]
        raise "Can't find field with possible names #{names} in #{row[:content].keys}" if value.nil?

        value
      end

      # Returns the next page unless there is none in which case nil
      # TODO: Handle things when next isn't a button with a postback
      def self.next(page)
        # Some of the systems don't have paging. All the results come
        # on a single page. In this case it shouldn't find a next link
        link = page.at(".rgPageNext")
        return if link.nil?

        # So far come across two different setups. One where the next
        # button is a postback link and one where the next button is a
        # form submit button.
        if link["href"] || link["onclick"]
          Postback.click(link, page)
        else
          current_page_no = current_index_page_no(page)
          page_links = page.at(".rgNumPart")
          next_page_link = page_links&.search("a")
                                     &.find { |a| a.inner_text == (current_page_no + 1).to_s }
          (Postback.click(next_page_link, page) if next_page_link)
        end
      end

      def self.current_index_page_no(page)
        page.at(".rgCurrentPage").inner_text.to_i
      end

      # Strips any html tags and decodes any html entities
      # e.g. "<strong>Tea &amp; Cake<strong>" => "Tea & Cake"
      def self.strip_html(html)
        Nokogiri::HTML(html).inner_text
      end
    end
  end
end
