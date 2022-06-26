module Vending
  # Accepts one coin into a buyer's balance.
  class Deposit < ApplicationService
    INVALID_AMOUNT = 'Invalid Amount'.freeze
    REJECTED = 'Deposit rejected'.freeze

    attr_reader :buyer, :amount, :coin_set

    def initialize(buyer:, amount:, coin_set: CoinSet.default)
      super()
      @buyer = buyer
      @amount = amount.to_i
      @coin_set = coin_set
    end

    def call
      return ServiceResult.failure(INVALID_AMOUNT) unless coin_set.accepts?(amount)

      if credit
        ServiceResult.success(buyer: buyer, deposit_amount: buyer.deposit_amount)
      else
        ServiceResult.failure(buyer.errors.full_messages.presence || [REJECTED])
      end
    end

    private

    # Without the row lock two coins inserted at once both add to the same
    # stale balance and one of them disappears.
    def credit
      buyer.with_lock { buyer.update_deposit_amount(amount, 'deposit') }
    end
  end
end
