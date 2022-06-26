# Turns an integer balance into the coins a machine would actually dispense.
#
# Pure domain logic: no ActiveRecord, no persistence, no side effects. The
# algorithm is greedy (largest denomination first), which is provably optimal
# for canonical coin systems such as the default 5/10/20/50/100 set. A custom
# non-canonical CoinSet (for example 1, 3, 4) may therefore receive more coins
# than the theoretical minimum - documented rather than hidden, because the
# alternative (dynamic programming over the amount) is unbounded in memory for
# an unbounded balance.
#
# A balance that is not exactly payable - 7 with a 5-and-up coin set - yields
# the coins that *can* be paid plus a non-zero `remainder`. The caller decides
# what to do with it; the machine must never silently swallow money.
class ChangeMaker
  # The coins to hand back, plus whatever could not be made up from them.
  Change = Struct.new(:coins, :remainder, keyword_init: true) do
    # Total value actually dispensed as coins.
    def total
      coins.sum { |denomination, count| denomination * count }
    end

    def exact?
      remainder.zero?
    end

    def coin_count
      coins.values.sum
    end

    def as_json(*)
      { 'coins' => coins.transform_keys(&:to_s), 'remainder' => remainder }
    end
  end

  attr_reader :coin_set

  def self.call(amount, coin_set: CoinSet.default)
    new(coin_set).call(amount)
  end

  def initialize(coin_set = CoinSet.default)
    @coin_set = coin_set
  end

  # @param amount [Integer] a non-negative balance in coin units
  # @return [Change]
  def call(amount)
    amount = Integer(amount)
    raise ArgumentError, 'amount must not be negative' if amount.negative?

    coins = {}
    remaining = amount

    coin_set.descending.each do |denomination|
      count, remaining = remaining.divmod(denomination)
      coins[denomination] = count if count.positive?
    end

    Change.new(coins: coins, remainder: remaining)
  end
end
