module Api
  module V1
    class RegistrationsController < DeviseTokenAuth::RegistrationsController
      include ExceptionHandler
      include ActAsApiRequest
      include Localizable

      before_action :require_known_role, only: :create

      private

      def sign_up_params
        params.require(:user).permit(:email, :password, :first_name, :last_name, :locale, :role)
      end

      # A user without a role can neither stock nor use the machine, and an
      # unknown value would make the enum raise, so the role is checked here.
      def require_known_role
        roles = User.roles.keys
        return if roles.include?(params.dig(:user, :role).to_s)

        render_attributes_errors(role: ["must be one of: #{roles.join(', ')}"])
      end

      def render_create_success
        render :create
      end

      def render_create_error
        raise ActiveRecord::RecordInvalid, @resource
      end

      def validate_post_data(which, message)
        render_errors(message, :bad_request) if which.empty?
      end
    end
  end
end
