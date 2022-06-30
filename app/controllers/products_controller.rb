# Read-only HTML view of the machine's contents, kept as a browsing/debugging
# convenience next to the JSON API. It has no authentication, so it exposes no
# write actions at all - every mutation goes through Api::V1::ProductsController,
# which authenticates the caller and checks that the seller owns the product.
class ProductsController < ApplicationController
  include Paginatable

  before_action :set_product, only: :show

  def index
    @pagy, @products = paginate(Product.order(:id))
  end

  def show; end

  private

  def set_product
    @product = Product.find(params[:id])
  end
end
