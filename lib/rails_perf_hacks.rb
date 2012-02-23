require 'active_support'
require 'active_support/multibyte'
require 'active_support/multibyte/utils'

module ActiveSupport
  module Multibyte
    class << self
       if !'string'.respond_to?(:force_encoding) && !Kernel.const_defined?(:Encoding)
        require 'rails_perf_hacks_ext'

        alias clean_slow clean
        def clean(string)
          if $KCODE == "UTF8"
            clean_fast(string)
          else
            clean_slow(string)
          end
        end
       end
    end
  end
end
