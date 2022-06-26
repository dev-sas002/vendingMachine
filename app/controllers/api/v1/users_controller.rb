module Api
  module V1
    class UsersController < Api::V1::ApiController
      include Paginatable

      helper_method :user

      before_action :require_check_if_changing_password, only: :update
      # There is no account left to refresh the auth headers of.
      skip_after_action :update_auth_header, only: :destroy

      def all
        @pagy, @users = paginate(User.order(:id))

        render :all
      end

      def show; end

      def update
        user.update!(user_params)
      end

      def destroy
        user.destroy!

        head :no_content
      end

      private

      def user
        @user ||= current_user
      end

      def require_check_if_changing_password
        return if !user_params[:password] || user.valid_password?(params[:password_check])

        render_errors(I18n.t('errors.authentication.invalid_password_check'), :bad_request)
      end

      def user_params
        # The role is fixed at registration: a buyer turning into a seller
        # mid-session would keep a balance a seller has no way to spend.
        params.require(:user).permit(:email, :password, :first_name, :last_name, :locale)
      end
    end
  end
end
