#include <ruby.h>
#include "diff.h"

#define DIFF_OPT_WITH_DEFAULT(option_name, hash, default_val, type) \
    do { \
        VALUE raw_ ## option_name ## _val = rb_hash_aref(hash, rb_str_new2( #option_name )); \
        if (raw_ ## option_name ## _val != Qnil) { \
            if (type == 'b') { \
                option_name = RTEST(raw_ ## option_name ## _val); \
            } else if (type == 'i') { \
                option_name = NUM2INT(raw_ ## option_name ## _val); \
            } \
        } else { \
            option_name = default_val; \
        } \
    } while (0)

VALUE Cardiff = Qnil;

VALUE GNUDiff = Qnil;

void Init_cardiff_gnu_diff(void);

static VALUE method_cardiff_gnu_diff_diff(int argc, VALUE *argv, VALUE self);

void Init_cardiff_gnu_diff() {
    Cardiff = rb_define_module("Cardiff");
    GNUDiff = rb_define_module_under(Cardiff, "GNUDiff");
    rb_define_singleton_method(GNUDiff, "diff_raw", method_cardiff_gnu_diff_diff, -1);
}

static void parse_diff_options(VALUE hash_options) {
    bool ignore_space_change = false; // -b option
    bool ignore_all_space = false; // -w option
    bool output_unified = false; // -u option
    output_style = OUTPUT_UNSPECIFIED;

    DIFF_OPT_WITH_DEFAULT(no_diff_means_no_output, hash_options, false, 'b');
    DIFF_OPT_WITH_DEFAULT(text, hash_options, true, 'b');
    DIFF_OPT_WITH_DEFAULT(horizon_lines, hash_options, 0, 'i');
    DIFF_OPT_WITH_DEFAULT(ignore_blank_lines, hash_options, false, 'b');
    DIFF_OPT_WITH_DEFAULT(ignore_case, hash_options, false, 'b');
    DIFF_OPT_WITH_DEFAULT(brief, hash_options, false, 'b');
    DIFF_OPT_WITH_DEFAULT(expand_tabs, hash_options, false, 'b');
    DIFF_OPT_WITH_DEFAULT(initial_tab, hash_options, false, 'b');

    // whitespace options:
    // ignore space change
    if (ignore_white_space == IGNORE_NO_WHITE_SPACE) {
        DIFF_OPT_WITH_DEFAULT(ignore_space_change, hash_options, false, 'b');
        if (ignore_space_change) {
            ignore_white_space = IGNORE_SPACE_CHANGE;
        }
    }
    // ignore all space
    if (ignore_white_space == IGNORE_NO_WHITE_SPACE) {
        DIFF_OPT_WITH_DEFAULT(ignore_all_space, hash_options, false, 'b');
        if (ignore_all_space) {
            ignore_white_space = IGNORE_ALL_SPACE;
        }
    }

    // output style options:
    DIFF_OPT_WITH_DEFAULT(context, hash_options, 0, 'i');
    if (context > 0 && output_style == OUTPUT_UNSPECIFIED) {
        if (context < 3) context = 3;
        output_style = OUTPUT_CONTEXT;
    }
    if (output_style == OUTPUT_UNSPECIFIED) {
        DIFF_OPT_WITH_DEFAULT(output_unified, hash_options, false, 'b');
        if (output_unified) {
            output_style = OUTPUT_UNIFIED;
            context = 3;
        }
    }
    // default output style
    if (output_style == OUTPUT_UNSPECIFIED) {
        output_style = OUTPUT_NORMAL;
    }

    if (horizon_lines < context) {
        horizon_lines = context;
    }
    tabsize = 8;
    time_format = "%Y-%m-%d %H:%M:%S %z";
    switch_string = "GNU DIFF";


#ifndef GUTTER_WIDTH_MINIMUM
# define GUTTER_WIDTH_MINIMUM 3
#endif
    size_t width = 130;
    intmax_t t = expand_tabs ? 1 : tabsize;
    intmax_t w = width;
    intmax_t off = (w + t + GUTTER_WIDTH_MINIMUM) / (2 * t)  *  t;
    sdiff_half_width = MAX (0, MIN (off - GUTTER_WIDTH_MINIMUM, w - off)),
    sdiff_column2_offset = sdiff_half_width ? off : w;
}

static VALUE method_cardiff_gnu_diff_diff(int argc, VALUE *argv, VALUE self) {
    VALUE str_file1, str_file2, hash_options;
    char *file1, *file2;
    int status;
    // 2 mandatory args (Strings for file1 and file2 paths) and 1 optional
    // argument (hash of options)
    rb_scan_args(argc, argv, "21", &str_file1, &str_file2, &hash_options);
    file1 = StringValueCStr(str_file1);
    file2 = StringValueCStr(str_file2);
    if (NIL_P(hash_options)) {
        hash_options = rb_hash_new();
    }
    parse_diff_options(hash_options);

    status = compare_files(NULL, file1, file2);
    return INT2NUM(status);
}
