#include "plutoprint.h"

static void page_size_free(void* data)
{
    xfree(data);
}

static size_t page_size_memsize(const void* data)
{
    return sizeof(plutobook_page_size_t);
}

const rb_data_type_t plutoprint_page_size_type = {
    "Plutoprint::PageSize",
    { NULL, page_size_free, page_size_memsize },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

plutobook_page_size_t* plutoprint_get_page_size(VALUE obj)
{
    plutobook_page_size_t* size;
    TypedData_Get_Struct(obj, plutobook_page_size_t, &plutoprint_page_size_type, size);
    return size;
}

plutobook_page_size_t plutoprint_create_page_size(VALUE obj)
{
    return *plutoprint_get_page_size(obj);
}

static VALUE page_size_alloc(VALUE klass)
{
    plutobook_page_size_t* size;
    VALUE obj = TypedData_Make_Struct(klass, plutobook_page_size_t, &plutoprint_page_size_type, size);
    size->width = 0.0f;
    size->height = 0.0f;
    return obj;
}

/*
 * call-seq:
 *   PageSize.new           -> PageSize (0, 0)
 *   PageSize.new(wh)       -> PageSize (wh, wh)
 *   PageSize.new(w, h)     -> PageSize (w, h)
 */
static VALUE page_size_initialize(int argc, VALUE* argv, VALUE self)
{
    plutobook_page_size_t* size;
    TypedData_Get_Struct(self, plutobook_page_size_t, &plutoprint_page_size_type, size);

    switch (argc) {
    case 0:
        size->width = 0.0f;
        size->height = 0.0f;
        break;
    case 1:
        size->width = (float)NUM2DBL(argv[0]);
        size->height = (float)NUM2DBL(argv[0]);
        break;
    case 2:
        size->width = (float)NUM2DBL(argv[0]);
        size->height = (float)NUM2DBL(argv[1]);
        break;
    default:
        rb_raise(rb_eArgError, "wrong number of arguments (given %d, expected 0..2)", argc);
    }

    return self;
}

static VALUE page_size_width(VALUE self)
{
    plutobook_page_size_t* size = plutoprint_get_page_size(self);
    return DBL2NUM((double)size->width);
}

static VALUE page_size_height(VALUE self)
{
    plutobook_page_size_t* size = plutoprint_get_page_size(self);
    return DBL2NUM((double)size->height);
}

static VALUE page_size_landscape(VALUE self)
{
    plutobook_page_size_t* size = plutoprint_get_page_size(self);
    float w = size->width;
    float h = size->height;
    float new_w = (w > h) ? w : h;
    float new_h = (w > h) ? h : w;

    VALUE result = page_size_alloc(cPageSize);
    plutobook_page_size_t* new_size = plutoprint_get_page_size(result);
    new_size->width = new_w;
    new_size->height = new_h;
    return result;
}

static VALUE page_size_portrait(VALUE self)
{
    plutobook_page_size_t* size = plutoprint_get_page_size(self);
    float w = size->width;
    float h = size->height;
    float new_w = (w < h) ? w : h;
    float new_h = (w < h) ? h : w;

    VALUE result = page_size_alloc(cPageSize);
    plutobook_page_size_t* new_size = plutoprint_get_page_size(result);
    new_size->width = new_w;
    new_size->height = new_h;
    return result;
}

static VALUE page_size_eq(VALUE self, VALUE other)
{
    if (!rb_obj_is_kind_of(other, cPageSize))
        return Qfalse;

    plutobook_page_size_t* a = plutoprint_get_page_size(self);
    plutobook_page_size_t* b = plutoprint_get_page_size(other);

    if (a->width == b->width && a->height == b->height)
        return Qtrue;
    return Qfalse;
}

static VALUE make_page_size_constant(float width, float height)
{
    VALUE obj = page_size_alloc(cPageSize);
    plutobook_page_size_t* size = plutoprint_get_page_size(obj);
    size->width = width;
    size->height = height;
    return obj;
}

void Init_plutoprint_page_size(void)
{
    cPageSize = rb_define_class_under(mPlutoprint, "PageSize", rb_cObject);
    rb_define_alloc_func(cPageSize, page_size_alloc);
    rb_define_method(cPageSize, "initialize", page_size_initialize, -1);
    rb_define_method(cPageSize, "width", page_size_width, 0);
    rb_define_method(cPageSize, "height", page_size_height, 0);
    rb_define_method(cPageSize, "landscape", page_size_landscape, 0);
    rb_define_method(cPageSize, "portrait", page_size_portrait, 0);
    rb_define_method(cPageSize, "==", page_size_eq, 1);

    /* Preset page size constants */
    {
        plutobook_page_size_t s;

        s = (plutobook_page_size_t)PLUTOBOOK_PAGE_SIZE_NONE;
        rb_define_const(mPlutoprint, "PAGE_SIZE_NONE", make_page_size_constant(s.width, s.height));

        s = (plutobook_page_size_t)PLUTOBOOK_PAGE_SIZE_A3;
        rb_define_const(mPlutoprint, "PAGE_SIZE_A3", make_page_size_constant(s.width, s.height));

        s = (plutobook_page_size_t)PLUTOBOOK_PAGE_SIZE_A4;
        rb_define_const(mPlutoprint, "PAGE_SIZE_A4", make_page_size_constant(s.width, s.height));

        s = (plutobook_page_size_t)PLUTOBOOK_PAGE_SIZE_A5;
        rb_define_const(mPlutoprint, "PAGE_SIZE_A5", make_page_size_constant(s.width, s.height));

        s = (plutobook_page_size_t)PLUTOBOOK_PAGE_SIZE_B4;
        rb_define_const(mPlutoprint, "PAGE_SIZE_B4", make_page_size_constant(s.width, s.height));

        s = (plutobook_page_size_t)PLUTOBOOK_PAGE_SIZE_B5;
        rb_define_const(mPlutoprint, "PAGE_SIZE_B5", make_page_size_constant(s.width, s.height));

        s = (plutobook_page_size_t)PLUTOBOOK_PAGE_SIZE_LETTER;
        rb_define_const(mPlutoprint, "PAGE_SIZE_LETTER", make_page_size_constant(s.width, s.height));

        s = (plutobook_page_size_t)PLUTOBOOK_PAGE_SIZE_LEGAL;
        rb_define_const(mPlutoprint, "PAGE_SIZE_LEGAL", make_page_size_constant(s.width, s.height));

        s = (plutobook_page_size_t)PLUTOBOOK_PAGE_SIZE_LEDGER;
        rb_define_const(mPlutoprint, "PAGE_SIZE_LEDGER", make_page_size_constant(s.width, s.height));
    }

    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_SIZE_NONE")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_SIZE_A3")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_SIZE_A4")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_SIZE_A5")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_SIZE_B4")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_SIZE_B5")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_SIZE_LETTER")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_SIZE_LEGAL")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_SIZE_LEDGER")));
}
