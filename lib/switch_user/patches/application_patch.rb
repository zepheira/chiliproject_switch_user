require_dependency 'application_controller'

module SwitchUser::Patches::ApplicationPatch
  def self.included(base)
    base.class_eval do
      # Returns the API 'switch user' value if present
      def api_switch_user_from_request
        request.headers["X-ChiliProject-Switch-User"].to_s.presence
      end

      # Returns the current user or nil if no user is logged in
      # and starts a session if needed
      def find_current_user
        user = nil
        unless api_request?
          if session[:user_id]
            # existing session
            user = (User.active.find(session[:user_id]) rescue nil)
          elsif cookies[Redmine::Configuration['autologin_cookie_name']] && Setting.autologin?
            # auto-login feature starts a new session
            user = User.try_to_autologin(cookies[Redmine::Configuration['autologin_cookie_name']])
            session[:user_id] = user.id if user
            user
          elsif params[:format] == 'atom' && params[:key] && accept_key_auth_actions.include?(params[:action])
            # RSS key authentication does not start a session
            User.find_by_rss_key(params[:key].to_s)
          end
        end
        if user.nil? && Setting.rest_api_enabled? && api_request?
          if (key = api_key_from_request) && accept_key_auth_actions.include?(params[:action])
            # Use API key
            user = User.find_by_api_key(key.to_s)
          else
            # HTTP Basic, either username/password or API key/random
            authenticate_with_http_basic do |username, password|
              user = User.try_to_login(username, password) || User.find_by_api_key(username)
            end
          end
          # Switch user if requested by an admin user
          if user && user.admin? && (username = api_switch_user_from_request)
            su = User.find_by_login(username)
            if su && su.active?
              logger.info(" User switched by: #{user.login} (id=#{user.id})") if logger
              user = su
            else
              render_error :message => 'Invalid X-ChiliProject-Switch-User header', :status => 412
            end
          end
        end
        user
      end
    end
  end

  module ClassMethods
  end
end

ApplicationController.send(:include, SwitchUser::Patches::ApplicationPatch)
