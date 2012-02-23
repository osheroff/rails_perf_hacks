require 'mkmf'
require 'rbconfig'

$CFLAGS="-g"
if CONFIG['CC'] =~ /gcc/
  $CFLAGS << ' -Wall'
end

create_makefile 'ext/rails_perf_hacks_ext'
