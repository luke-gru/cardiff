#include <ruby.h>
#include "../vendor/diffutils/src/diff.h"

VALUE Cardiff = Qnil;

VALUE GNUDiff = Qnil;

void Init_cardiff_gnu_diff(void);

VALUE method_cardiff_gnu_diff_diff(VALUE self, VALUE string_a, VALUE string_b);

void Init_cardiff_gnu_diff() {
    Cardiff = rb_define_module("Cardiff");
    GNUDiff = rb_define_module_under(Cardiff, "GNUDiff");
    rb_define_singleton_method(GNUDiff, "diff", method_cardiff_gnu_diff_diff, 2);
}

VALUE method_cardiff_gnu_diff_diff(VALUE self, VALUE string_a, VALUE string_b) {
    return INT2NUM(47);
}
