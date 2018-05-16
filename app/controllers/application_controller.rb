class ApplicationController < ActionController::Base
  protect_from_forgery

  private

  # This is done by Devise. Cf.
  # https://github.com/plataformatec/devise/wiki/How-To:-Change-the-redirect-path-after-destroying-a-session-i.e.-signing-out
  def after_sign_out_path_for(resource_or_scope)
    if CfiOauthProvider::Application.config.use_keycloak
      return "#{CfiOauthProvider::Application.config.keycloak_logout_uri}?redirect_uri=#{CfiOauthProvider::Application.config.default_link_url}"
    elsif not request[:redirect_uri].nil? then
      request[:redirect_uri]
    else
      ''
    end
  end

end
