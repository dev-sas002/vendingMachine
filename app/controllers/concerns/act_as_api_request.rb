# Shared behaviour for every controller that speaks JSON: the API namespace and
# the devise_token_auth controllers that live outside it.
module ActAsApiRequest
  extend ActiveSupport::Concern

  included do
    before_action :force_json_format
    before_action :skip_session_storage
    before_action :check_request_type
  end

  # These controllers have no HTML representation. Without this, a client that
  # posts a JSON body but sends no `Accept` header negotiates `text/html` and
  # the response renderer fails looking for a template that does not exist.
  def force_json_format
    request.format = :json
  end

  def check_request_type
    return if request_body.empty?

    allowed_types = %w[json form-data]
    content_type = request.content_type

    return if content_type.match(Regexp.union(allowed_types))

    render json: { error: I18n.t('errors.invalid_content_type') }, status: :bad_request
  end

  def skip_session_storage
    request.session_options[:skip] = true
  end

  private

  def request_body
    request.body.read
  end
end
