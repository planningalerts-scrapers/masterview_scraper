# frozen_string_literal: true

module MasterviewScraper
  # Help with handling asp.net doPostBack
  module Postback
    # Implement a click on a link that understands stupid asp.net doPostBack
    def self.click(doc, page)
      return if doc["onclick"] =~ /return false;/

      # TODO: Just follow the link likes it's a normal link
      raise unless doc["onclick"] =~ /javascript:__doPostBack\('(.*)','(.*)'\)/

      form = page.form_with(id: "aspnetForm")
      form["__EVENTTARGET"] = Regexp.last_match(1)
      form["__EVENTARGUMENT"] = Regexp.last_match(2)
      form.submit
    end
  end
end
