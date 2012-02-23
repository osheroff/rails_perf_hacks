require 'mkmf'
require 'rbconfig'

$CFLAGS="-g -O3"
if CONFIG['CC'] =~ /gcc/
  $CFLAGS << ' -Wall'
end

create_makefile 'ext/rails_perf_hacks_ext'
