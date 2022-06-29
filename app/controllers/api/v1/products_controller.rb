module Api
  module V1
    class ProductsController < Api::V1::ApiController
      include Paginatable

      before_action :set_product, only: %i[show update destroy]
      before_action :authorize_seller, only: :create
      before_action :authorize_product_owner, only: %i[update destroy]

      def index
        # `includes(:seller)` keeps the seller block in the payload at two
        # queries regardless of page size; without it this is a textbook N+1.
        @pagy, @products = paginate(Product.includes(:seller).order(:id))

        render :index
      end

      def show
        render :show
      end

      def create
        @product = Product.new(product_params)
        @product.seller ||= current_user

        if @product.save
          render :show, status: :created
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @product.update(product_params)
          render :show
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @product.destroy
          render :show, status: :ok
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      # Only sellers may add products to the machine.
      def authorize_seller
        return if current_user&.seller?

        render json: { error: 'Only sellers can manage products' }, status: :forbidden
      end

      # A seller may only change or remove their own products.
      def authorize_product_owner
        return if current_user.present? && current_user == @product.seller

        render json: { error: 'Only sellers can manage products' }, status: :forbidden
      end

      def set_product
        @product = Product.find(params[:id])
      end

      def product_params
        ProductAttributes.from(params)
      end
    end
  end
end
