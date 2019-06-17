# frozen_string_literal: true

module MasterviewScraper
  module Pages
    # The first page with the annoying agree button on it
    module TermsAndConditions
      def self.click_agree(page)
        # Click the Agree button on the form
        form = if page.forms.count == 1
                 page.forms[0]
               else
                 page.form_with(id: "aspnetForm") ||
                   page.form_with(id: "frmApplicationMaster") ||
                   page.form_with(id: "frmMasterView")
               end
        raise "Couldn't find form" if form.nil?

        button = form.button_with(value: /Agree/)
        raise "Can't find agree button" if button.nil?

        form.submit(button)
      end
    end
  end
end
