module Vending
  # Empties a buyer's balance and reports the coins the machine hands back.
  #
  # The balance is zeroed and the change is computed from the amount that was
  # actually on the machine, so the two can never disagree. A balance that the
  # coin set cannot make up exactly (a price of 7 leaves 3 behind) is reported
  # as `remainder` instead of being quietly lost.
  class Refund < ApplicationService
    FAILED = 'Deposit could not be reset'.freeze

    attr_reader :buyer, :coin_set

    def initialize(buyer:, coin_set: CoinSet.default)
      super()
      @buyer = buyer
      @coin_set = coin_set
    end

    def call
      returned_amount = buyer.deposit_amount.to_i

      unless buyer.update(deposit_amount: 0)
        return ServiceResult.failure(buyer.errors.full_messages.presence || [FAILED])
      end

      ServiceResult.success(buyer: buyer,
                            returned_amount: returned_amount,
                            change: ChangeMaker.call(returned_amount, coin_set: coin_set))
    end
  end
end
