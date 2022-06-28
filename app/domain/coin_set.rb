# The set of coin denominations a machine accepts.
#
# The denominations are a property of the machine, not of a controller, so they
# live here as a value object. `CoinSet.default` reads `COIN_DENOMINATIONS`
# from the environment, which is the seam to deploy the same code against a
# different currency without touching the API layer:
#
#   COIN_DENOMINATIONS=1,2,5,10,20,50,100,200   # euro cents
#
# Instances are immutable and cheap; pass one into ChangeMaker or a Vending
# service to override the machine's currency for a single call.
class CoinSet
  DEFAULT_DENOMINATIONS = [5, 10, 20, 50, 100].freeze
  ENV_KEY = 'COIN_DENOMINATIONS'.freeze

  attr_reader :denominations

  class << self
    # Memoised so the environment is parsed once per process. Tests that need a
    # different set build their own instance rather than mutating this one.
    def default
      @default ||= new(denominations_from_env)
    end

    def reset_default!
      @default = nil
    end

    private

    def denominations_from_env
      raw = ENV.fetch(ENV_KEY, nil)
      return DEFAULT_DENOMINATIONS if raw.nil? || raw.strip.empty?

      raw.split(',').map { |value| Integer(value.strip) }
    end
  end

  def initialize(denominations = DEFAULT_DENOMINATIONS)
    values = Array(denominations).map { |value| Integer(value) }.uniq.sort
    raise ArgumentError, 'a coin set needs at least one denomination' if values.empty?
    raise ArgumentError, 'denominations must be positive' unless values.all?(&:positive?)

    @denominations = values.freeze
    @descending = values.reverse.freeze
    freeze
  end

  # Denominations largest first - the order the greedy change algorithm wants.
  attr_reader :descending

  def accepts?(amount)
    denominations.include?(amount)
  end

  def smallest
    denominations.first
  end

  def to_a
    denominations.dup
  end

  def ==(other)
    other.is_a?(CoinSet) && other.denominations == denominations
  end
  alias eql? ==

  def hash
    denominations.hash
  end
end
