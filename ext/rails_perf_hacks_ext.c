#include "ruby.h"
#include <string.h>

 
 /*
  a straight-C implementation of this regexp. 
  *       'UTF-8' => /\A(?:
                  [\x00-\x7f]                                         |
                  [\xc2-\xdf] [\x80-\xbf]                             |
                  \xe0        [\xa0-\xbf] [\x80-\xbf]                 |
                  [\xe1-\xef] [\x80-\xbf] [\x80-\xbf]                 |
                  \xf0        [\x90-\xbf] [\x80-\xbf] [\x80-\xbf]     |
                  [\xf1-\xf3] [\x80-\xbf] [\x80-\xbf] [\x80-\xbf]     |
                  \xf4        [\x80-\x8f] [\x80-\xbf] [\x80-\xbf])\z /xn,
 */

#define VALIDISH(x) ((x >= 0x80) && x <= 0xBf)
#define OVERRUN(value, p, x) ((p - (unsigned char *)RSTRING_PTR(value)) + x > RSTRING_LEN(value))
VALUE multibyte_clean(VALUE self, VALUE string)
{
  unsigned char *p, *new;

  VALUE new_str = rb_str_new(NULL, RSTRING_LEN(string));

  new = (unsigned char *) RSTRING_PTR(new_str);
  p = (unsigned char *) RSTRING_PTR(string);
  while ( p < (RSTRING_PTR(string) + RSTRING_LEN(string)) ) {
    if ( *p < 128 ) {
      if ( OVERRUN(string, p, 1) )
        break;

      *new++ = *p++;
    } else if ( *p >= 0xc2 && *p <= 0xdf ) {
      if ( OVERRUN(string, p, 2) )
        break;

      if ( VALIDISH(p[1]) ) {
        strncpy(new, p, 2);
        new += 2;
      }

      p += 2;
    } else if ( *p >= 0xe0 && *p <= 0xef ) {
      if ( OVERRUN(string, p, 3) ) 
        break;

      if ( VALIDISH(p[1]) && VALIDISH(p[2]) &&
            !(p[0] == 0xE0 && p[1] < 0xA0) ) {
        strncpy(new, p, 3);
        new += 3;
      }

      p += 3;
    } else if ( *p >= 0xf0 && *p <= 0xf4 ) {
      if ( OVERRUN(string, p, 4) ) 
        break;

      if ( VALIDISH(p[1]) && VALIDISH(p[2]) && VALIDISH(p[3])
            && !(p[0] == 0xf0 && p[1] < 0x90) 
            && !(p[0] == 0xf4 && p[1] > 0x8f) ) {
        strncpy(new, p, 4);
        new += 4;
      }

      p += 4;
    } else {
      p++;
      continue;
    }
  }

  RSTRING_LEN(new_str) = (new - (unsigned char *)RSTRING_PTR(new_str));
  return new_str;
}


void Init_rails_perf_hacks_ext()
{
  VALUE cUtils;
  rb_require("active_support/multibyte/utils");
  cUtils = rb_path2class("ActiveSupport::Multibyte");
  rb_define_singleton_method(cUtils, "clean_fast", multibyte_clean, 1);
}
