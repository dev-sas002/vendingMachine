# Liveness/readiness probe for the container healthcheck and any load balancer
# in front of the app. Deliberately unauthenticated and deliberately cheap: it
# proves the process is up and that it can still reach the database, and says
# nothing else.
class HealthController < ActionController::API
  def show
    ActiveRecord::Base.connection.execute('SELECT 1')

    render json: { status: 'ok', database: 'ok' }
  rescue StandardError
    render json: { status: 'error', database: 'unreachable' }, status: :service_unavailable
  end
end
