class ApplicationController < ActionController::Base
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  before_action :authenticate

  private

  def authenticate
    authenticate_or_request_with_http_basic("Watchlist") do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, BASIC_AUTH_USERNAME) &
        ActiveSupport::SecurityUtils.secure_compare(password, BASIC_AUTH_PASSWORD)
    end
  end
end
