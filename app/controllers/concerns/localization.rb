# Chooses the language for each request: the user's saved choice,
# otherwise their browser's language, otherwise English.
module Localization
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private

  def switch_locale(&action)
    I18n.with_locale(chosen_locale, &action)
  end

  def chosen_locale
    saved = cookies[:locale].to_s
    return saved if I18n.available_locales.map(&:to_s).include?(saved)

    browser = request.env["HTTP_ACCEPT_LANGUAGE"].to_s.downcase
    browser.start_with?("ja") ? :ja : I18n.default_locale
  end
end
