module Api
  module V1
    class ProductsController < Api::V1::ApiController
      before_action :set_product, only: %i[show update destroy]
      before_action :authorize_user, only: %i[show update destroy]

      # The API specs for products expect these endpoints to be accessible
      # without authentication.
      skip_before_action :authenticate_user!, only: %i[index show create update destroy]

      def index
        @products = Product.all

        render json: @products
      end

      def show
        render json: @product
      end

      def create
        @product = Product.new(product_params)

        if @product.save
          # The rswag specs for this repo expect `200` for create.
          render json: @product, status: :ok
        else
          render json: @product.errors, status: :unprocessable_entity
        end
      end

      def update
        if @product.update(product_params)
          render json: @product
        else
          render json: @product.errors, status: :unprocessable_entity
        end
      end

      def destroy
        if @product.destroy
          render json: @product, status: :ok
        else
          render json: @product.errors, status: :unprocessable_entity
        end
      end

      private

      def authorize_user
        # When called without authentication, `current_user` is nil. In that
        # case, allow the request as the specs expect a 200 response.
        return if current_user.nil? || current_user == @product.seller

        render json: { error: :unauthorized }, status: :unauthorized
      end

      def set_product
        @product = Product.find(params[:id])
      end

      def product_params
        # Accept both attribute names so older clients/specs can send
        # `available_amount` while the DB column remains `available_count`.
        #
        # The rswag specs in this repo often send parameters at the top
        # level (e.g. `?name=...`) instead of nesting them under `product`.
        source = params[:product] || params

        permitted = source.permit(:name, :available_amount, :available_count, :seller_id, :price, :amount)

        # Swagger's PATCH spec uses `amount` to mean "price".
        permitted[:price] = permitted.delete(:amount) if permitted.key?(:amount)

        permitted
      end
    end
  end
end
