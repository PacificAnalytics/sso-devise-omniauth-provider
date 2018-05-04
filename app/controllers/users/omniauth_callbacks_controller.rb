require 'jwt'

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  skip_before_filter :verify_authenticity_token, :only => [:google, :google_oauth2, :keycloak]

  def google
    begin
      @user = User.authenticate(:google, request.env['omniauth.auth']['info']['email'],
                                request.env['omniauth.auth']['uid'],
                                current_user)
      do_sign_in
    rescue => e
      logger.warn e.backtrace
      @error = e
      render 'failure', status: :forbidden
    end
  end

  def google_oauth2
    begin
      begin
        @user = User.authenticate(:google_oauth2,
                                  request.env['omniauth.auth']['info']['email'],
                                  request.env['omniauth.auth']['uid'],
                                  current_user)
      rescue User::EmailCollision => e
        if openid_id = JWT.decode(request.env['omniauth.auth']['extra']['id_token']).payload[:openid_id]
          # Try OpenId
          @user = User.authenticate(:google,
                                    request.env['omniauth.auth']['info']['email'],
                                    openid_id,
                                    current_user)
          # Create authentication record for OAuth2
          auth = Authentication.new
          auth.user_id = @user.id
          auth.provider = :google_oauth2
          auth.uid = request.env['omniauth.auth']['uid']
          auth.save!
        else
          raise
        end
      end

      do_sign_in
    rescue => e
      logger.warn e.backtrace
      @error = e
      render 'failure', status: :forbidden
    end
  end

  def ldap
    ldap_conf = CfiOauthProvider::Application.config.use_ldap
    info = request.env['omniauth.auth']['info']

    if !info['email'].nil? and !info['email'].empty?
      email = request.env['omniauth.auth']['info']['email']
    elsif !ldap_conf["email_domain"].nil? and !ldap_conf["email_domain"].empty?
      email = info['nickname'] + "@" + ldap_conf["email_domain"]
    else
      render 'failure', status: :forbidden
      return
    end

    username = if ldap_conf['username']
                 request.env['omniauth.auth']['extra']['raw_info'][ldap_conf['username'].to_sym][0]
               end

    begin
      @user = User.authenticate(:ldap,
                                email,
                                request.env['omniauth.auth']['uid'],
                                current_user,
                                username: username)
      do_sign_in "LDAP"
    rescue => e
      logger.warn e.backtrace
      @error = e
      render 'failure', status: :forbidden
    end
  end

  def keycloak
    @user = User.authenticate(:keycloak, request.env['omniauth.auth']['info']['email'],
                              request.env['omniauth.auth']['uid'],
                              current_user)
    do_sign_in "KEYCLOAK"
  end
  
  protected

  def do_sign_in(kind="Google")
    @user.first_name = request.env['omniauth.auth']['info']['first_name'] || request.env['omniauth.auth']['info']['name']
    @user.last_name = request.env['omniauth.auth']['info']['last_name']
    @user.save

    current_user = @user

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => kind
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.google_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
end
