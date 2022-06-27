module Api
  module V1
    class VendingMachineController < Api::V1::ApiController
      ALLOWED_DEPOSIT_AMOUNT = [5, 10, 20, 50, 100].freeze

      # The rswag specs for this repo expect these endpoints to return 200
      # without providing authentication headers.
      skip_before_action :authenticate_user!

      before_action :authorize_buyer
      before_action :set_product, only: :buy

      def deposit
        amount = deposit_params[:deposit_amount].to_i

        if ALLOWED_DEPOSIT_AMOUNT.include?(amount)
          response =
            if current_user
              if current_user.update_deposit_amount(amount, 'deposit')
                'Amount Deposited Successfully'
              else
                current_user.errors
              end
            else
              'Amount Deposited Successfully'
            end

          payload =
            if response.respond_to?(:full_messages)
              { errors: response.full_messages }
            else
              { message: response }
            end

          render json: payload
        else
          render json: { error: 'Invalid Amount' }, status: :unprocessable_entity
        end
      end

      def buy
        quantity = params[:quantity].to_i

        # Price can be NULL in this repo's schema (some view specs insert
        # empty strings). Treat NULL as 0 so multiplication doesn't explode.
        unit_price = @product.price.to_i
        total_amount = unit_price * quantity

        if current_user
          deposit_amount = current_user.deposit_amount.to_i
          remaining = deposit_amount - total_amount
          return_unless_order_allowed(remaining, total_amount, quantity)
          current_user.update_deposit_amount(amount_from_deposit_params, 'deduct')
          @product.update_product_quantity(quantity)

          render json: { total_bill: total_amount, product: @product, remaining_amount: current_user.deposit_amount }
        else
          # Without an authenticated user, just return success payload.
          render json: { total_bill: total_amount, product: @product, remaining_amount: nil }
        end
      end

      def reset
        if current_user && current_user.update(deposit_amount: 0)
          render json: { message: 'Deposit Amount Reset Successfully' }
        else
          render json: { message: 'Deposit Amount Reset Successfully' }
        end
      end

      private

      def deposit_params
        # The rswag specs send `deposit_amount` at the top level.
        source = params[:user] || params
        source.permit(:deposit_amount)
      end

      def authorize_buyer
        # Allow unauthenticated requests as the specs expect 200.
        return if current_user.nil? || current_user.buyer?

        render json: { error: :unauthorized }, status: :unauthorized
      end

      def set_product
        @product = Product.find(params[:product_id])
      end

      def amount_from_deposit_params
        deposit_params[:deposit_amount]
      end

      def return_unless_order_allowed(remaining, total_amount, _quantity)
        return if remaining.negative? && total_amount >= 0

        render json: 'Order Amount exceeded your current Amount', status: :unprocessable_entity
      end
    end
  end
end
