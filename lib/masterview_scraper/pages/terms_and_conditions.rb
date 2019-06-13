# frozen_string_literal: true

module MasterviewScraper
  module Pages
    # The first page with the annoying agree button on it
    module TermsAndConditions
      def self.click_agree(page)
        # Click the Agree button on the form
        button = page.form.button_with(value: /Agree/)
        raise "Can't find agree button" if button.nil?

        page.form.submit(button)
      end
    end
  end
end
