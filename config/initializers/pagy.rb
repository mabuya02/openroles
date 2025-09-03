# frozen_string_literal: true

# Pagy initializer file (8.6.5)
# Customize only what you really need but notice that the core Pagy works also without any of the following lines.
# Should you just cherry pick part of this file, please maintain the require-order of the extras

# Pagy DEFAULT: you can set your own default vars in this initializer file and/or
# as an argument in each pagy call
# See https://ddnexus.github.io/pagy/docs/api/pagy#variables
# All the Pagy::DEFAULT are set for all the Pagy instances but can be overridden
# per instance by just passing them to Pagy.new or the #pagy controller method

# Core DEFAULT variables
Pagy::DEFAULT[:limit] = 20                       # items per page
Pagy::DEFAULT[:size]  = 7                        # nav bar size

# Extra: Bootstrap 5 nav helper
require "pagy/extras/bootstrap"

# Custom helper to disable Turbo for pagination links
module Pagy::Frontend
  def pagy_bootstrap_nav_no_turbo(pagy, pagy_id: nil, link_extra: "", **vars)
    link_extra = %(#{link_extra} data-turbo="false") # Disable Turbo for pagination links
    pagy_bootstrap_nav(pagy, pagy_id: pagy_id, link_extra: link_extra, **vars)
  end
end

# Extra: Support for non-integer keys (when you need to paginate UUIDs or other ID formats)
# require 'pagy/extras/keyset'

# Extra: Support for paginating active record collections
require "pagy/extras/array"
