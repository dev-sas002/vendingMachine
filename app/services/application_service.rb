# Base class for the service (use case) layer.
#
# A service is a single business operation with a single public entry point.
# `Service.call(...)` builds and runs one; instances are never reused.
class ApplicationService
  def self.call(...)
    new(...).call
  end

  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end
end
