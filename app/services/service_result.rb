# The single return type of every service object.
#
# Controllers branch on `success?` and read the payload; they never have to
# know whether a failure came from a validation, a business rule or a lost race
# for the last item of stock.
class ServiceResult
  attr_reader :error, :payload

  def self.success(**payload)
    new(error: nil, payload: payload)
  end

  def self.failure(error, **payload)
    new(error: error, payload: payload)
  end

  def initialize(error:, payload: {})
    @error = error
    @payload = payload.freeze
    freeze
  end

  def success?
    error.nil?
  end

  def failure?
    !success?
  end

  delegate :[], to: :payload
end
