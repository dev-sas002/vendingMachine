# Base class for the handful of controllers that are not part of the JSON API:
# the read-only HTML product pages and the devise_token_auth controllers, which
# inherit from the gem's own ActionController::Base descendants.
class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true, with: :exception, unless: :api_request?

  private

  # CSRF protection exists to stop a browser form being submitted from another
  # origin. A browser cannot send `Content-Type: application/json` cross-origin
  # without a CORS preflight, so a JSON body is proof that the caller is an API
  # client rather than a forged form post.
  #
  # Checking the content type as well as the negotiated format matters: a client
  # that sends a JSON body but no `Accept` header used to be answered with a
  # 500 InvalidAuthenticityToken from `POST /api/v1/users/sign_in`.
  def api_request?
    request.format.json? || request.content_type.to_s.include?('json')
  end
end
