class LocalesController < ApplicationController
  def update
    locale = params[:locale].to_s
    if I18n.available_locales.map(&:to_s).include?(locale)
      cookies.permanent[:locale] = { value: locale, same_site: :lax }
    end
    redirect_back fallback_location: you_path
  end
end
