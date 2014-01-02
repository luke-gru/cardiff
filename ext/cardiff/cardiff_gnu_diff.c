#include <ruby.h>
#include "diff.h"

VALUE Cardiff = Qnil;

VALUE GNUDiff = Qnil;

void Init_cardiff_gnu_diff(void);

VALUE method_cardiff_gnu_diff_diff(VALUE self, VALUE filenamea, VALUE filenameb);

void Init_cardiff_gnu_diff() {
    Cardiff = rb_define_module("Cardiff");
    GNUDiff = rb_define_module_under(Cardiff, "GNUDiff");
    rb_define_singleton_method(GNUDiff, "diff", method_cardiff_gnu_diff_diff, 2);
}

VALUE method_cardiff_gnu_diff_diff(VALUE self, VALUE filenamea, VALUE filenameb) {
    char *file1 = StringValueCStr(filenamea);
    char *file2 = StringValueCStr(filenameb);
    /*struct comparison *cmp = get_cmp_info_from_2_filenames(file1, file2);*/
    no_diff_means_no_output = false;
    text = true;
    horizon_lines = 0;
    ignore_blank_lines = true;
    ignore_case = false;
    ignore_file_name_case = false;
    brief = false;
    expand_tabs = false;
    initial_tab = false;
    output_style = OUTPUT_NORMAL;
    switch_string = "GNU DIFF";

    int status = compare_files(NULL, file1, file2);
    return INT2NUM(status);
}

