module Vending
  # Charges a buyer and releases stock as one unit of work.
  #
  # Concurrency contract
  # --------------------
  # Two things can be raced: the buyer's balance and the product's stock.
  #
  # * The balance is protected by a `SELECT ... FOR UPDATE` on the buyer row, so
  #   two sessions spending the same wallet serialise against each other.
  # * The stock is protected by a conditional `UPDATE products SET
  #   available_count = available_count - n WHERE id = ? AND available_count >= n`
  #   (see Product#decrement_stock!). Under READ COMMITTED Postgres re-evaluates
  #   that predicate after taking the row lock, so exactly one of two concurrent
  #   buyers for the last item wins and stock can never go negative.
  #
  # Locks are always taken buyer-then-product, so no two sessions can build a
  # cycle and deadlock.
  #
  # `requires_new: true` forces a real savepoint, so ActiveRecord::Rollback still
  # unwinds the work when this runs inside an outer transaction - RSpec's
  # transactional fixtures, for example.
  class Purchase < ApplicationService
    INVALID_QUANTITY = 'Quantity must be greater than zero'.freeze
    INSUFFICIENT_FUNDS = 'Order Amount exceeded your current Amount'.freeze
    SOLD_OUT = 'Product is sold out'.freeze
    NOT_ENOUGH_STOCK = 'Not enough stock available'.freeze

    attr_reader :buyer, :product, :quantity, :coin_set

    def initialize(buyer:, product:, quantity:, coin_set: CoinSet.default)
      super()
      @buyer = buyer
      @product = product
      @quantity = quantity.to_i
      @coin_set = coin_set
    end

    def call
      return ServiceResult.failure(INVALID_QUANTITY) unless quantity.positive?

      locked_buyer = nil
      error = nil

      ActiveRecord::Base.transaction(requires_new: true) do
        locked_buyer = User.lock.find(buyer.id)
        error = settle(locked_buyer)
        raise ActiveRecord::Rollback if error
      end

      return failure(error) if error

      success(locked_buyer)
    end

    private

    def total_amount
      @total_amount ||= product.price.to_i * quantity
    end

    # Runs inside the transaction with the buyer row locked. Returns an error
    # message, or nil when the purchase went through.
    def settle(locked_buyer)
      return INSUFFICIENT_FUNDS if locked_buyer.deposit_amount.to_i < total_amount
      return stock_error unless product.decrement_stock!(quantity)

      INSUFFICIENT_FUNDS unless locked_buyer.update_deposit_amount(total_amount, 'deduct')
    end

    def stock_error
      product.reload.sold_out? ? SOLD_OUT : NOT_ENOUGH_STOCK
    end

    def failure(error)
      # The caller renders the product, so hand back a row that reflects what is
      # actually committed rather than anything the rolled-back attempt touched.
      product.reload
      ServiceResult.failure(error, product: product, buyer: buyer)
    end

    def success(locked_buyer)
      remaining = locked_buyer.deposit_amount.to_i

      ServiceResult.success(
        buyer: locked_buyer,
        product: product,
        total_amount: total_amount,
        remaining_amount: remaining,
        change: ChangeMaker.call(remaining, coin_set: coin_set)
      )
    end
  end
end
