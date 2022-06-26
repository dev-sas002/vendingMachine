module Api
  module V1
    # Thin HTTP adapter over the Vending service layer: parse params, call one
    # service, render its result. All of the money and stock rules live in
    # app/services/vending and app/domain.
    class VendingMachineController < Api::V1::ApiController
      before_action :authorize_buyer
      before_action :set_product, only: :buy

      def deposit
        result = Vending::Deposit.call(buyer: current_user, amount: deposit_params[:deposit_amount])

        return render_service_error(result) if result.failure?

        render json: { message: 'Amount Deposited Successfully',
                       deposit_amount: result[:deposit_amount] }
      end

      def buy
        result = Vending::Purchase.call(buyer: current_user, product: @product,
                                        quantity: params[:quantity])

        return render_service_error(result) if result.failure?

        @total_bill = result[:total_amount]
        @remaining_amount = result[:remaining_amount]
        @change = result[:change]

        render :buy
      end

      def reset
        result = Vending::Refund.call(buyer: current_user)

        return render_service_error(result) if result.failure?

        render json: { message: 'Deposit Amount Reset Successfully',
                       returned_amount: result[:returned_amount],
                       change: result[:change] }
      end

      private

      # Services report a single message for a broken business rule and a list
      # for model validation failures; keep both response shapes stable.
      def render_service_error(result)
        error = result.error
        key = error.is_a?(Array) ? :errors : :error

        render json: { key => error }, status: :unprocessable_entity
      end

      def deposit_params
        # `deposit_amount` may arrive nested under `user` or at the top level.
        source = params[:user] || params
        source.permit(:deposit_amount)
      end

      def authorize_buyer
        return if current_user&.buyer?

        render json: { error: 'Only buyers can use the vending machine' }, status: :forbidden
      end

      def set_product
        @product = Product.find(params[:product_id])
      end
    end
  end
end
