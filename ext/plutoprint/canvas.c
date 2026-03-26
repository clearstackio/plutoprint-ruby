#include "plutoprint.h"

/* Canvas wrapper struct */
typedef struct {
    plutobook_canvas_t* canvas;
} plutoprint_canvas_wrapper_t;

static void canvas_dfree(void* data)
{
    plutoprint_canvas_wrapper_t* wrapper = (plutoprint_canvas_wrapper_t*)data;
    if (wrapper->canvas) {
        plutobook_canvas_destroy(wrapper->canvas);
        wrapper->canvas = NULL;
    }
    xfree(wrapper);
}

static size_t canvas_memsize(const void* data)
{
    return sizeof(plutoprint_canvas_wrapper_t);
}

const rb_data_type_t plutoprint_canvas_type = {
    "Plutoprint::Canvas",
    { NULL, canvas_dfree, canvas_memsize },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

plutobook_canvas_t* plutoprint_get_canvas(VALUE obj)
{
    plutoprint_canvas_wrapper_t* wrapper;
    TypedData_Get_Struct(obj, plutoprint_canvas_wrapper_t, &plutoprint_canvas_type, wrapper);
    if (!wrapper->canvas) {
        rb_raise(ePlutoprintError, "canvas has been finished");
    }
    return wrapper->canvas;
}

static VALUE canvas_alloc(VALUE klass)
{
    plutoprint_canvas_wrapper_t* wrapper;
    VALUE obj = TypedData_Make_Struct(klass, plutoprint_canvas_wrapper_t, &plutoprint_canvas_type, wrapper);
    wrapper->canvas = NULL;
    return obj;
}

/* Canvas base class methods */

static VALUE canvas_flush(VALUE self)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_canvas_flush(canvas);
    return self;
}

static VALUE canvas_finish(VALUE self)
{
    plutoprint_canvas_wrapper_t* wrapper;
    TypedData_Get_Struct(self, plutoprint_canvas_wrapper_t, &plutoprint_canvas_type, wrapper);
    if (wrapper->canvas) {
        plutobook_canvas_finish(wrapper->canvas);
        plutobook_canvas_destroy(wrapper->canvas);
        wrapper->canvas = NULL;
    }
    return self;
}

static VALUE canvas_translate(VALUE self, VALUE tx, VALUE ty)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_canvas_translate(canvas, (float)NUM2DBL(tx), (float)NUM2DBL(ty));
    return self;
}

static VALUE canvas_scale(VALUE self, VALUE sx, VALUE sy)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_canvas_scale(canvas, (float)NUM2DBL(sx), (float)NUM2DBL(sy));
    return self;
}

static VALUE canvas_rotate(VALUE self, VALUE angle)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_canvas_rotate(canvas, (float)NUM2DBL(angle));
    return self;
}

static VALUE canvas_transform(VALUE self, VALUE a, VALUE b, VALUE c, VALUE d, VALUE e, VALUE f)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_canvas_transform(canvas,
        (float)NUM2DBL(a), (float)NUM2DBL(b), (float)NUM2DBL(c),
        (float)NUM2DBL(d), (float)NUM2DBL(e), (float)NUM2DBL(f));
    return self;
}

static VALUE canvas_set_matrix(VALUE self, VALUE a, VALUE b, VALUE c, VALUE d, VALUE e, VALUE f)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_canvas_set_matrix(canvas,
        (float)NUM2DBL(a), (float)NUM2DBL(b), (float)NUM2DBL(c),
        (float)NUM2DBL(d), (float)NUM2DBL(e), (float)NUM2DBL(f));
    return self;
}

static VALUE canvas_reset_matrix(VALUE self)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_canvas_reset_matrix(canvas);
    return self;
}

static VALUE canvas_clip_rect(VALUE self, VALUE x, VALUE y, VALUE w, VALUE h)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_canvas_clip_rect(canvas,
        (float)NUM2DBL(x), (float)NUM2DBL(y),
        (float)NUM2DBL(w), (float)NUM2DBL(h));
    return self;
}

static VALUE canvas_clear_surface(int argc, VALUE* argv, VALUE self)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    VALUE r, g, b, a;
    rb_scan_args(argc, argv, "31", &r, &g, &b, &a);
    float alpha = NIL_P(a) ? 1.0f : (float)NUM2DBL(a);
    plutobook_canvas_clear_surface(canvas,
        (float)NUM2DBL(r), (float)NUM2DBL(g), (float)NUM2DBL(b), alpha);
    return self;
}

static VALUE canvas_save_state(VALUE self)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_canvas_save_state(canvas);
    return self;
}

static VALUE canvas_restore_state(VALUE self)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_canvas_restore_state(canvas);
    return self;
}

/* ImageCanvas */

static VALUE image_canvas_initialize(int argc, VALUE* argv, VALUE self)
{
    plutoprint_canvas_wrapper_t* wrapper;
    TypedData_Get_Struct(self, plutoprint_canvas_wrapper_t, &plutoprint_canvas_type, wrapper);

    VALUE width, height, format;
    rb_scan_args(argc, argv, "21", &width, &height, &format);

    plutobook_image_format_t fmt = NIL_P(format) ? PLUTOBOOK_IMAGE_FORMAT_ARGB32 : (plutobook_image_format_t)NUM2INT(format);
    wrapper->canvas = plutobook_image_canvas_create(NUM2INT(width), NUM2INT(height), fmt);
    if (!wrapper->canvas) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    return self;
}

static VALUE image_canvas_create_for_data(int argc, VALUE* argv, VALUE klass)
{
    VALUE data, width, height, stride, format;
    rb_scan_args(argc, argv, "41", &data, &width, &height, &stride, &format);
    Check_Type(data, T_STRING);

    plutobook_image_format_t fmt = NIL_P(format) ? PLUTOBOOK_IMAGE_FORMAT_ARGB32 : (plutobook_image_format_t)NUM2INT(format);

    VALUE obj = canvas_alloc(klass);
    plutoprint_canvas_wrapper_t* wrapper;
    TypedData_Get_Struct(obj, plutoprint_canvas_wrapper_t, &plutoprint_canvas_type, wrapper);

    wrapper->canvas = plutobook_image_canvas_create_for_data(
        (unsigned char*)RSTRING_PTR(data),
        NUM2INT(width), NUM2INT(height), NUM2INT(stride), fmt);
    if (!wrapper->canvas) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }

    /* Prevent GC of the data string */
    rb_ivar_set(obj, rb_intern("@data_ref"), data);
    return obj;
}

static VALUE image_canvas_width(VALUE self)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    return INT2NUM(plutobook_image_canvas_get_width(canvas));
}

static VALUE image_canvas_height(VALUE self)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    return INT2NUM(plutobook_image_canvas_get_height(canvas));
}

static VALUE image_canvas_stride(VALUE self)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    return INT2NUM(plutobook_image_canvas_get_stride(canvas));
}

static VALUE image_canvas_format(VALUE self)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    return INT2NUM((int)plutobook_image_canvas_get_format(canvas));
}

static VALUE image_canvas_data(VALUE self)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    unsigned char* data = plutobook_image_canvas_get_data(canvas);
    int height = plutobook_image_canvas_get_height(canvas);
    int stride = plutobook_image_canvas_get_stride(canvas);
    if (!data) return Qnil;
    return rb_str_new((const char*)data, (long)height * stride);
}

static VALUE image_canvas_write_to_png(VALUE self, VALUE path)
{
    Check_Type(path, T_STRING);
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    if (!plutobook_image_canvas_write_to_png(canvas, StringValueCStr(path))) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    return self;
}

static VALUE image_canvas_write_to_png_stream(VALUE self, VALUE io)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    if (!plutobook_image_canvas_write_to_png_stream(canvas, plutoprint_stream_write_callback, (void*)io)) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    RB_GC_GUARD(io);
    return self;
}

/* PDFCanvas */

static VALUE pdf_canvas_initialize(VALUE self, VALUE path, VALUE size_obj)
{
    Check_Type(path, T_STRING);
    plutoprint_canvas_wrapper_t* wrapper;
    TypedData_Get_Struct(self, plutoprint_canvas_wrapper_t, &plutoprint_canvas_type, wrapper);

    plutobook_page_size_t size = plutoprint_create_page_size(size_obj);
    wrapper->canvas = plutobook_pdf_canvas_create(StringValueCStr(path), size);
    if (!wrapper->canvas) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }
    return self;
}

static VALUE pdf_canvas_create_for_stream(VALUE klass, VALUE io, VALUE size_obj)
{
    plutobook_page_size_t size = plutoprint_create_page_size(size_obj);

    VALUE obj = canvas_alloc(klass);
    plutoprint_canvas_wrapper_t* wrapper;
    TypedData_Get_Struct(obj, plutoprint_canvas_wrapper_t, &plutoprint_canvas_type, wrapper);

    wrapper->canvas = plutobook_pdf_canvas_create_for_stream(
        plutoprint_stream_write_callback, (void*)io, size);
    if (!wrapper->canvas) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }

    /* Prevent GC of the IO object */
    rb_ivar_set(obj, rb_intern("@io_ref"), io);
    return obj;
}

static VALUE pdf_canvas_set_metadata(VALUE self, VALUE key, VALUE value)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    Check_Type(value, T_STRING);
    plutobook_pdf_canvas_set_metadata(canvas, (plutobook_pdf_metadata_t)NUM2INT(key), StringValueCStr(value));
    return self;
}

static VALUE pdf_canvas_set_size(VALUE self, VALUE size_obj)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_page_size_t size = plutoprint_create_page_size(size_obj);
    plutobook_pdf_canvas_set_size(canvas, size);
    return self;
}

static VALUE pdf_canvas_show_page(VALUE self)
{
    plutobook_canvas_t* canvas = plutoprint_get_canvas(self);
    plutobook_pdf_canvas_show_page(canvas);
    return self;
}

void Init_plutoprint_canvas(void)
{
    /* Canvas base class */
    cCanvas = rb_define_class_under(mPlutoprint, "Canvas", rb_cObject);
    rb_define_alloc_func(cCanvas, canvas_alloc);
    rb_define_method(cCanvas, "flush", canvas_flush, 0);
    rb_define_method(cCanvas, "finish", canvas_finish, 0);
    rb_define_method(cCanvas, "translate", canvas_translate, 2);
    rb_define_method(cCanvas, "scale", canvas_scale, 2);
    rb_define_method(cCanvas, "rotate", canvas_rotate, 1);
    rb_define_method(cCanvas, "transform", canvas_transform, 6);
    rb_define_method(cCanvas, "set_matrix", canvas_set_matrix, 6);
    rb_define_method(cCanvas, "reset_matrix", canvas_reset_matrix, 0);
    rb_define_method(cCanvas, "clip_rect", canvas_clip_rect, 4);
    rb_define_method(cCanvas, "clear_surface", canvas_clear_surface, -1);
    rb_define_method(cCanvas, "save_state", canvas_save_state, 0);
    rb_define_method(cCanvas, "restore_state", canvas_restore_state, 0);

    /* ImageCanvas subclass */
    cImageCanvas = rb_define_class_under(mPlutoprint, "ImageCanvas", cCanvas);
    rb_define_method(cImageCanvas, "initialize", image_canvas_initialize, -1);
    rb_define_singleton_method(cImageCanvas, "create_for_data", image_canvas_create_for_data, -1);
    rb_define_method(cImageCanvas, "width", image_canvas_width, 0);
    rb_define_method(cImageCanvas, "height", image_canvas_height, 0);
    rb_define_method(cImageCanvas, "stride", image_canvas_stride, 0);
    rb_define_method(cImageCanvas, "format", image_canvas_format, 0);
    rb_define_method(cImageCanvas, "data", image_canvas_data, 0);
    rb_define_method(cImageCanvas, "write_to_png", image_canvas_write_to_png, 1);
    rb_define_method(cImageCanvas, "write_to_png_stream", image_canvas_write_to_png_stream, 1);

    /* PDFCanvas subclass */
    cPDFCanvas = rb_define_class_under(mPlutoprint, "PDFCanvas", cCanvas);
    rb_define_method(cPDFCanvas, "initialize", pdf_canvas_initialize, 2);
    rb_define_singleton_method(cPDFCanvas, "create_for_stream", pdf_canvas_create_for_stream, 2);
    rb_define_method(cPDFCanvas, "set_metadata", pdf_canvas_set_metadata, 2);
    rb_define_method(cPDFCanvas, "set_size", pdf_canvas_set_size, 1);
    rb_define_method(cPDFCanvas, "show_page", pdf_canvas_show_page, 0);
}
