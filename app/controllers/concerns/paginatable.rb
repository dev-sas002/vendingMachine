# Bounded collection responses.
#
# Every index endpoint goes through `paginate` so no request can ever ask the
# database for an unbounded result set. The caller may raise or lower the page
# size with `?items=`, but never above MAX_PAGE_SIZE.
#
# Pagy's `headers` extra emits the standard `Link`, `Current-Page`,
# `Page-Items`, `Total-Pages` and `Total-Count` response headers, so clients can
# page without the envelope changing shape.
module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PAGE_SIZE = 25
  MAX_PAGE_SIZE = 100

  included do
    include Pagy::Backend
  end

  private

  def paginate(scope)
    pagy, records = pagy(scope, items: page_size)
    pagy_headers_merge(pagy)

    [pagy, records]
  end

  def page_size
    requested = params[:items].to_i

    return DEFAULT_PAGE_SIZE unless requested.positive?

    [requested, MAX_PAGE_SIZE].min
  end
end
