class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit]

  def index
    @products = Product.all
  end

  def show; end

  def new
    @product = Product.new
  end

  def edit; end

  private

  def set_product
    @product = Product.find(params[:id])
  end
end

