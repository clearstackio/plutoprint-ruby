#include "plutoprint.h"

/* Book wrapper struct */
typedef struct {
    plutobook_t* book;
    VALUE custom_resource_fetcher;
} plutoprint_book_wrapper_t;

static void book_mark(void* data)
{
    plutoprint_book_wrapper_t* wrapper = (plutoprint_book_wrapper_t*)data;
    rb_gc_mark(wrapper->custom_resource_fetcher);
}

static void book_dfree(void* data)
{
    plutoprint_book_wrapper_t* wrapper = (plutoprint_book_wrapper_t*)data;
    if (wrapper->book) {
        plutobook_destroy(wrapper->book);
        wrapper->book = NULL;
    }
    xfree(wrapper);
}

static size_t book_memsize(const void* data)
{
    return sizeof(plutoprint_book_wrapper_t);
}

const rb_data_type_t plutoprint_book_type = {
    "Plutoprint::Book",
    { book_mark, book_dfree, book_memsize },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

static plutoprint_book_wrapper_t* get_book_wrapper(VALUE self)
{
    plutoprint_book_wrapper_t* wrapper;
    TypedData_Get_Struct(self, plutoprint_book_wrapper_t, &plutoprint_book_type, wrapper);
    if (!wrapper->book) {
        rb_raise(ePlutoprintError, "book has been destroyed");
    }
    return wrapper;
}

static VALUE book_alloc(VALUE klass)
{
    plutoprint_book_wrapper_t* wrapper;
    VALUE obj = TypedData_Make_Struct(klass, plutoprint_book_wrapper_t, &plutoprint_book_type, wrapper);
    wrapper->book = NULL;
    wrapper->custom_resource_fetcher = Qnil;
    return obj;
}

static VALUE book_initialize(int argc, VALUE* argv, VALUE self)
{
    plutoprint_book_wrapper_t* wrapper;
    TypedData_Get_Struct(self, plutoprint_book_wrapper_t, &plutoprint_book_type, wrapper);

    VALUE size_obj, margins_obj, media_obj;
    rb_scan_args(argc, argv, "03", &size_obj, &margins_obj, &media_obj);

    plutobook_page_size_t size;
    if (NIL_P(size_obj)) {
        size = (plutobook_page_size_t)PLUTOBOOK_PAGE_SIZE_A4;
    } else {
        size = plutoprint_create_page_size(size_obj);
    }

    plutobook_page_margins_t margins;
    if (NIL_P(margins_obj)) {
        margins = (plutobook_page_margins_t)PLUTOBOOK_PAGE_MARGINS_NORMAL;
    } else {
        margins = plutoprint_create_page_margins(margins_obj);
    }

    plutobook_media_type_t media = NIL_P(media_obj)
        ? PLUTOBOOK_MEDIA_TYPE_PRINT
        : (plutobook_media_type_t)NUM2INT(media_obj);

    wrapper->book = plutobook_create(size, margins, media);
    if (!wrapper->book) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }

    return self;
}

/* Query methods */

static VALUE book_viewport_width(VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    return DBL2NUM((double)plutobook_get_viewport_width(w->book));
}

static VALUE book_viewport_height(VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    return DBL2NUM((double)plutobook_get_viewport_height(w->book));
}

static VALUE book_document_width(VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    return DBL2NUM((double)plutobook_get_document_width(w->book));
}

static VALUE book_document_height(VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    return DBL2NUM((double)plutobook_get_document_height(w->book));
}

static VALUE book_page_count(VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    return UINT2NUM(plutobook_get_page_count(w->book));
}

static VALUE book_page_size(VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    plutobook_page_size_t size = plutobook_get_page_size(w->book);

    VALUE obj = rb_obj_alloc(cPageSize);
    plutobook_page_size_t* s = plutoprint_get_page_size(obj);
    *s = size;
    return obj;
}

static VALUE book_page_size_at(VALUE self, VALUE index)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    plutobook_page_size_t size = plutobook_get_page_size_at(w->book, NUM2UINT(index));

    VALUE obj = rb_obj_alloc(cPageSize);
    plutobook_page_size_t* s = plutoprint_get_page_size(obj);
    *s = size;
    return obj;
}

static VALUE book_page_margins(VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    plutobook_page_margins_t margins = plutobook_get_page_margins(w->book);

    VALUE obj = rb_obj_alloc(cPageMargins);
    plutobook_page_margins_t* m = plutoprint_get_page_margins(obj);
    *m = margins;
    return obj;
}

static VALUE book_media_type(VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    return INT2NUM((int)plutobook_get_media_type(w->book));
}

/* Metadata */

static VALUE book_set_metadata(VALUE self, VALUE key, VALUE value)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    Check_Type(value, T_STRING);
    plutobook_set_metadata(w->book, (plutobook_pdf_metadata_t)NUM2INT(key), StringValueCStr(value));
    return self;
}

static VALUE book_metadata(VALUE self, VALUE key)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    const char* val = plutobook_get_metadata(w->book, (plutobook_pdf_metadata_t)NUM2INT(key));
    return rb_str_new_cstr(val ? val : "");
}

/* Load methods */

static VALUE book_load_url(int argc, VALUE* argv, VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    VALUE url, user_style, user_script;
    rb_scan_args(argc, argv, "12", &url, &user_style, &user_script);
    Check_Type(url, T_STRING);

    const char* style = NIL_P(user_style) ? "" : StringValueCStr(user_style);
    const char* script = NIL_P(user_script) ? "" : StringValueCStr(user_script);

    if (!plutobook_load_url(w->book, StringValueCStr(url), style, script)) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    return self;
}

static VALUE book_load_html(int argc, VALUE* argv, VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    VALUE data, user_style, user_script, base_url;
    rb_scan_args(argc, argv, "13", &data, &user_style, &user_script, &base_url);
    Check_Type(data, T_STRING);

    const char* style = NIL_P(user_style) ? "" : StringValueCStr(user_style);
    const char* script = NIL_P(user_script) ? "" : StringValueCStr(user_script);
    const char* base = NIL_P(base_url) ? "" : StringValueCStr(base_url);

    if (!plutobook_load_html(w->book, RSTRING_PTR(data), (int)RSTRING_LEN(data), style, script, base)) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    return self;
}

static VALUE book_load_xml(int argc, VALUE* argv, VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    VALUE data, user_style, user_script, base_url;
    rb_scan_args(argc, argv, "13", &data, &user_style, &user_script, &base_url);
    Check_Type(data, T_STRING);

    const char* style = NIL_P(user_style) ? "" : StringValueCStr(user_style);
    const char* script = NIL_P(user_script) ? "" : StringValueCStr(user_script);
    const char* base = NIL_P(base_url) ? "" : StringValueCStr(base_url);

    if (!plutobook_load_xml(w->book, RSTRING_PTR(data), (int)RSTRING_LEN(data), style, script, base)) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    return self;
}

static VALUE book_load_data(int argc, VALUE* argv, VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    VALUE data, mime, enc, style, script, base;
    rb_scan_args(argc, argv, "15", &data, &mime, &enc, &style, &script, &base);
    Check_Type(data, T_STRING);

    const char* c_mime = NIL_P(mime) ? "" : StringValueCStr(mime);
    const char* c_enc = NIL_P(enc) ? "" : StringValueCStr(enc);
    const char* c_style = NIL_P(style) ? "" : StringValueCStr(style);
    const char* c_script = NIL_P(script) ? "" : StringValueCStr(script);
    const char* c_base = NIL_P(base) ? "" : StringValueCStr(base);

    if (!plutobook_load_data(w->book, RSTRING_PTR(data), (unsigned int)RSTRING_LEN(data),
            c_mime, c_enc, c_style, c_script, c_base)) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    return self;
}

static VALUE book_load_image(int argc, VALUE* argv, VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    VALUE data, mime, enc, style, script, base;
    rb_scan_args(argc, argv, "15", &data, &mime, &enc, &style, &script, &base);
    Check_Type(data, T_STRING);

    const char* c_mime = NIL_P(mime) ? "" : StringValueCStr(mime);
    const char* c_enc = NIL_P(enc) ? "" : StringValueCStr(enc);
    const char* c_style = NIL_P(style) ? "" : StringValueCStr(style);
    const char* c_script = NIL_P(script) ? "" : StringValueCStr(script);
    const char* c_base = NIL_P(base) ? "" : StringValueCStr(base);

    if (!plutobook_load_image(w->book, RSTRING_PTR(data), (unsigned int)RSTRING_LEN(data),
            c_mime, c_enc, c_style, c_script, c_base)) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    return self;
}

static VALUE book_clear_content(VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    plutobook_clear_content(w->book);
    return self;
}

/* Render methods */

static VALUE book_render_page(VALUE self, VALUE canvas_obj, VALUE page_index)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    plutobook_canvas_t* canvas = plutoprint_get_canvas(canvas_obj);
    plutobook_render_page(w->book, canvas, NUM2UINT(page_index));
    return self;
}

static VALUE book_render_document(VALUE self, VALUE canvas_obj)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    plutobook_canvas_t* canvas = plutoprint_get_canvas(canvas_obj);
    plutobook_render_document(w->book, canvas);
    return self;
}

static VALUE book_render_document_rect(VALUE self, VALUE canvas_obj, VALUE x, VALUE y, VALUE width, VALUE height)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    plutobook_canvas_t* canvas = plutoprint_get_canvas(canvas_obj);
    plutobook_render_document_rect(w->book, canvas,
        (float)NUM2DBL(x), (float)NUM2DBL(y),
        (float)NUM2DBL(width), (float)NUM2DBL(height));
    return self;
}

/* Export methods */

static VALUE book_write_to_pdf(int argc, VALUE* argv, VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    VALUE filename, page_start, page_end, page_step;
    rb_scan_args(argc, argv, "13", &filename, &page_start, &page_end, &page_step);
    Check_Type(filename, T_STRING);

    bool result;
    if (NIL_P(page_start)) {
        result = plutobook_write_to_pdf(w->book, StringValueCStr(filename));
    } else {
        unsigned int start = NUM2UINT(page_start);
        unsigned int end = NIL_P(page_end) ? PLUTOBOOK_MAX_PAGE_COUNT : NUM2UINT(page_end);
        int step = NIL_P(page_step) ? 1 : NUM2INT(page_step);
        result = plutobook_write_to_pdf_range(w->book, StringValueCStr(filename), start, end, step);
    }

    if (!result) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    return self;
}

static VALUE book_write_to_pdf_stream(int argc, VALUE* argv, VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    VALUE io, page_start, page_end, page_step;
    rb_scan_args(argc, argv, "13", &io, &page_start, &page_end, &page_step);

    bool result;
    if (NIL_P(page_start)) {
        result = plutobook_write_to_pdf_stream(w->book, plutoprint_stream_write_callback, (void*)io);
    } else {
        unsigned int start = NUM2UINT(page_start);
        unsigned int end = NIL_P(page_end) ? PLUTOBOOK_MAX_PAGE_COUNT : NUM2UINT(page_end);
        int step = NIL_P(page_step) ? 1 : NUM2INT(page_step);
        result = plutobook_write_to_pdf_stream_range(w->book, plutoprint_stream_write_callback, (void*)io, start, end, step);
    }

    if (!result) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    RB_GC_GUARD(io);
    return self;
}

static VALUE book_write_to_png(int argc, VALUE* argv, VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    VALUE filename, width, height;
    rb_scan_args(argc, argv, "12", &filename, &width, &height);
    Check_Type(filename, T_STRING);

    int w_val = NIL_P(width) ? -1 : NUM2INT(width);
    int h_val = NIL_P(height) ? -1 : NUM2INT(height);

    if (!plutobook_write_to_png(w->book, StringValueCStr(filename), w_val, h_val)) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    return self;
}

static VALUE book_write_to_png_stream(int argc, VALUE* argv, VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    VALUE io, width, height;
    rb_scan_args(argc, argv, "12", &io, &width, &height);

    int w_val = NIL_P(width) ? -1 : NUM2INT(width);
    int h_val = NIL_P(height) ? -1 : NUM2INT(height);

    if (!plutobook_write_to_png_stream(w->book, plutoprint_stream_write_callback, (void*)io, w_val, h_val)) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    RB_GC_GUARD(io);
    return self;
}

/* Custom resource fetcher */

static VALUE book_custom_resource_fetcher(VALUE self)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);
    return w->custom_resource_fetcher;
}

static VALUE book_set_custom_resource_fetcher(VALUE self, VALUE fetcher)
{
    plutoprint_book_wrapper_t* w = get_book_wrapper(self);

    if (NIL_P(fetcher)) {
        w->custom_resource_fetcher = Qnil;
        plutobook_set_custom_resource_fetcher(w->book, NULL, NULL);
    } else {
        w->custom_resource_fetcher = fetcher;
        plutobook_set_custom_resource_fetcher(w->book, plutoprint_resource_fetch_func, (void*)fetcher);
    }
    return fetcher;
}

void Init_plutoprint_book(void)
{
    cBook = rb_define_class_under(mPlutoprint, "Book", rb_cObject);
    rb_define_alloc_func(cBook, book_alloc);
    rb_define_method(cBook, "initialize", book_initialize, -1);

    /* Query methods */
    rb_define_method(cBook, "viewport_width", book_viewport_width, 0);
    rb_define_method(cBook, "viewport_height", book_viewport_height, 0);
    rb_define_method(cBook, "document_width", book_document_width, 0);
    rb_define_method(cBook, "document_height", book_document_height, 0);
    rb_define_method(cBook, "page_count", book_page_count, 0);
    rb_define_method(cBook, "page_size", book_page_size, 0);
    rb_define_method(cBook, "page_size_at", book_page_size_at, 1);
    rb_define_method(cBook, "page_margins", book_page_margins, 0);
    rb_define_method(cBook, "media_type", book_media_type, 0);

    /* Metadata */
    rb_define_method(cBook, "set_metadata", book_set_metadata, 2);
    rb_define_method(cBook, "metadata", book_metadata, 1);

    /* Load methods */
    rb_define_method(cBook, "load_url", book_load_url, -1);
    rb_define_method(cBook, "load_html", book_load_html, -1);
    rb_define_method(cBook, "load_xml", book_load_xml, -1);
    rb_define_method(cBook, "load_data", book_load_data, -1);
    rb_define_method(cBook, "load_image", book_load_image, -1);
    rb_define_method(cBook, "clear_content", book_clear_content, 0);

    /* Render methods */
    rb_define_method(cBook, "render_page", book_render_page, 2);
    rb_define_method(cBook, "render_document", book_render_document, 1);
    rb_define_method(cBook, "render_document_rect", book_render_document_rect, 5);

    /* Export methods */
    rb_define_method(cBook, "write_to_pdf", book_write_to_pdf, -1);
    rb_define_method(cBook, "write_to_pdf_stream", book_write_to_pdf_stream, -1);
    rb_define_method(cBook, "write_to_png", book_write_to_png, -1);
    rb_define_method(cBook, "write_to_png_stream", book_write_to_png_stream, -1);

    /* Custom resource fetcher */
    rb_define_method(cBook, "custom_resource_fetcher", book_custom_resource_fetcher, 0);
    rb_define_method(cBook, "custom_resource_fetcher=", book_set_custom_resource_fetcher, 1);
}
