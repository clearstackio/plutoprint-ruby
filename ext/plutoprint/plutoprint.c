#include "plutoprint.h"

VALUE mPlutoprint;
VALUE ePlutoprintError;
VALUE cPageSize;
VALUE cPageMargins;
VALUE cCanvas;
VALUE cImageCanvas;
VALUE cPDFCanvas;
VALUE cBook;
VALUE cResourceData;
VALUE cResourceFetcher;
VALUE cDefaultResourceFetcher;

/* Stream write callback - calls Ruby IO#write */
plutobook_stream_status_t plutoprint_stream_write_callback(void* closure, const char* data, unsigned int length)
{
    VALUE io = (VALUE)closure;
    VALUE str = rb_str_new(data, length);
    rb_funcall(io, rb_intern("write"), 1, str);
    return PLUTOBOOK_STREAM_STATUS_SUCCESS;
}

/* Module methods */
static VALUE plutoprint_plutobook_version(VALUE self)
{
    return INT2NUM(plutobook_version());
}

static VALUE plutoprint_plutobook_version_string(VALUE self)
{
    return rb_str_new_cstr(plutobook_version_string());
}

static VALUE plutoprint_plutobook_build_info(VALUE self)
{
    return rb_str_new_cstr(plutobook_build_info());
}

static VALUE plutoprint_set_fontconfig_path(VALUE self, VALUE path)
{
    Check_Type(path, T_STRING);
    plutobook_set_fontconfig_path(StringValueCStr(path));
    return Qnil;
}

void Init_plutoprint(void)
{
    mPlutoprint = rb_define_module("Plutoprint");
    ePlutoprintError = rb_define_class_under(mPlutoprint, "Error", rb_eStandardError);

    /* Unit constants */
    rb_define_const(mPlutoprint, "UNITS_PT", DBL2NUM(PLUTOBOOK_UNITS_PT));
    rb_define_const(mPlutoprint, "UNITS_PC", DBL2NUM(PLUTOBOOK_UNITS_PC));
    rb_define_const(mPlutoprint, "UNITS_IN", DBL2NUM(PLUTOBOOK_UNITS_IN));
    rb_define_const(mPlutoprint, "UNITS_CM", DBL2NUM(PLUTOBOOK_UNITS_CM));
    rb_define_const(mPlutoprint, "UNITS_MM", DBL2NUM(PLUTOBOOK_UNITS_MM));
    rb_define_const(mPlutoprint, "UNITS_PX", DBL2NUM(PLUTOBOOK_UNITS_PX));

    /* Media type constants */
    rb_define_const(mPlutoprint, "MEDIA_TYPE_PRINT", INT2NUM(PLUTOBOOK_MEDIA_TYPE_PRINT));
    rb_define_const(mPlutoprint, "MEDIA_TYPE_SCREEN", INT2NUM(PLUTOBOOK_MEDIA_TYPE_SCREEN));

    /* PDF metadata constants */
    rb_define_const(mPlutoprint, "PDF_METADATA_TITLE", INT2NUM(PLUTOBOOK_PDF_METADATA_TITLE));
    rb_define_const(mPlutoprint, "PDF_METADATA_AUTHOR", INT2NUM(PLUTOBOOK_PDF_METADATA_AUTHOR));
    rb_define_const(mPlutoprint, "PDF_METADATA_SUBJECT", INT2NUM(PLUTOBOOK_PDF_METADATA_SUBJECT));
    rb_define_const(mPlutoprint, "PDF_METADATA_KEYWORDS", INT2NUM(PLUTOBOOK_PDF_METADATA_KEYWORDS));
    rb_define_const(mPlutoprint, "PDF_METADATA_CREATOR", INT2NUM(PLUTOBOOK_PDF_METADATA_CREATOR));
    rb_define_const(mPlutoprint, "PDF_METADATA_CREATION_DATE", INT2NUM(PLUTOBOOK_PDF_METADATA_CREATION_DATE));
    rb_define_const(mPlutoprint, "PDF_METADATA_MODIFICATION_DATE", INT2NUM(PLUTOBOOK_PDF_METADATA_MODIFICATION_DATE));

    /* Image format constants */
    rb_define_const(mPlutoprint, "IMAGE_FORMAT_INVALID", INT2NUM(PLUTOBOOK_IMAGE_FORMAT_INVALID));
    rb_define_const(mPlutoprint, "IMAGE_FORMAT_ARGB32", INT2NUM(PLUTOBOOK_IMAGE_FORMAT_ARGB32));
    rb_define_const(mPlutoprint, "IMAGE_FORMAT_RGB24", INT2NUM(PLUTOBOOK_IMAGE_FORMAT_RGB24));
    rb_define_const(mPlutoprint, "IMAGE_FORMAT_A8", INT2NUM(PLUTOBOOK_IMAGE_FORMAT_A8));
    rb_define_const(mPlutoprint, "IMAGE_FORMAT_A1", INT2NUM(PLUTOBOOK_IMAGE_FORMAT_A1));

    /* Page count constants */
    rb_define_const(mPlutoprint, "MIN_PAGE_COUNT", UINT2NUM(PLUTOBOOK_MIN_PAGE_COUNT));
    rb_define_const(mPlutoprint, "MAX_PAGE_COUNT", UINT2NUM(PLUTOBOOK_MAX_PAGE_COUNT));

    /* Version constants */
    rb_define_const(mPlutoprint, "PLUTOBOOK_VERSION", INT2NUM(PLUTOBOOK_VERSION));
    rb_define_const(mPlutoprint, "PLUTOBOOK_VERSION_MAJOR", INT2NUM(PLUTOBOOK_VERSION_MAJOR));
    rb_define_const(mPlutoprint, "PLUTOBOOK_VERSION_MINOR", INT2NUM(PLUTOBOOK_VERSION_MINOR));
    rb_define_const(mPlutoprint, "PLUTOBOOK_VERSION_MICRO", INT2NUM(PLUTOBOOK_VERSION_MICRO));
    rb_define_const(mPlutoprint, "PLUTOBOOK_VERSION_STRING", rb_str_new_cstr(PLUTOBOOK_VERSION_STRING));

    /* Module functions */
    rb_define_module_function(mPlutoprint, "plutobook_version", plutoprint_plutobook_version, 0);
    rb_define_module_function(mPlutoprint, "plutobook_version_string", plutoprint_plutobook_version_string, 0);
    rb_define_module_function(mPlutoprint, "plutobook_build_info", plutoprint_plutobook_build_info, 0);
    rb_define_module_function(mPlutoprint, "set_fontconfig_path", plutoprint_set_fontconfig_path, 1);

    /* Initialize sub-modules */
    Init_plutoprint_page_size();
    Init_plutoprint_page_margins();
    Init_plutoprint_canvas();
    Init_plutoprint_book();
    Init_plutoprint_resource_data();
    Init_plutoprint_resource_fetcher();
}
