# Normalises the several shapes the products API accepts into one attribute
# hash, so the controller does not have to know about any of them.
#
# Callers may send the fields nested under `product` or at the top level, may
# call the stock `available_amount` or `available_count`, and - in the documented
# PATCH operation - call the price `amount`.
class ProductAttributes
  PERMITTED = %i[name available_amount available_count seller_id price amount].freeze

  def self.from(params)
    new((params[:product] || params).permit(*PERMITTED)).to_h
  end

  def initialize(permitted)
    @permitted = permitted
  end

  def to_h
    return @permitted unless @permitted.key?(:amount)

    @permitted.except(:amount).merge(price: @permitted[:amount])
  end
end
