#include "plutoprint.h"

static void page_margins_free(void* data)
{
    xfree(data);
}

static size_t page_margins_memsize(const void* data)
{
    return sizeof(plutobook_page_margins_t);
}

const rb_data_type_t plutoprint_page_margins_type = {
    "Plutoprint::PageMargins",
    { NULL, page_margins_free, page_margins_memsize },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

plutobook_page_margins_t* plutoprint_get_page_margins(VALUE obj)
{
    plutobook_page_margins_t* margins;
    TypedData_Get_Struct(obj, plutobook_page_margins_t, &plutoprint_page_margins_type, margins);
    return margins;
}

plutobook_page_margins_t plutoprint_create_page_margins(VALUE obj)
{
    return *plutoprint_get_page_margins(obj);
}

static VALUE page_margins_alloc(VALUE klass)
{
    plutobook_page_margins_t* margins;
    VALUE obj = TypedData_Make_Struct(klass, plutobook_page_margins_t, &plutoprint_page_margins_type, margins);
    margins->top = 0.0f;
    margins->right = 0.0f;
    margins->bottom = 0.0f;
    margins->left = 0.0f;
    return obj;
}

/*
 * call-seq:
 *   PageMargins.new                     -> PageMargins (0, 0, 0, 0)
 *   PageMargins.new(all)                -> PageMargins (all, all, all, all)
 *   PageMargins.new(tb, rl)             -> PageMargins (tb, rl, tb, rl)
 *   PageMargins.new(t, rl, b)           -> PageMargins (t, rl, b, rl)
 *   PageMargins.new(t, r, b, l)         -> PageMargins (t, r, b, l)
 */
static VALUE page_margins_initialize(int argc, VALUE* argv, VALUE self)
{
    plutobook_page_margins_t* margins;
    TypedData_Get_Struct(self, plutobook_page_margins_t, &plutoprint_page_margins_type, margins);

    switch (argc) {
    case 0:
        margins->top = 0.0f;
        margins->right = 0.0f;
        margins->bottom = 0.0f;
        margins->left = 0.0f;
        break;
    case 1: {
        float all = (float)NUM2DBL(argv[0]);
        margins->top = all;
        margins->right = all;
        margins->bottom = all;
        margins->left = all;
        break;
    }
    case 2: {
        float tb = (float)NUM2DBL(argv[0]);
        float rl = (float)NUM2DBL(argv[1]);
        margins->top = tb;
        margins->right = rl;
        margins->bottom = tb;
        margins->left = rl;
        break;
    }
    case 3: {
        float t = (float)NUM2DBL(argv[0]);
        float rl = (float)NUM2DBL(argv[1]);
        float b = (float)NUM2DBL(argv[2]);
        margins->top = t;
        margins->right = rl;
        margins->bottom = b;
        margins->left = rl;
        break;
    }
    case 4:
        margins->top = (float)NUM2DBL(argv[0]);
        margins->right = (float)NUM2DBL(argv[1]);
        margins->bottom = (float)NUM2DBL(argv[2]);
        margins->left = (float)NUM2DBL(argv[3]);
        break;
    default:
        rb_raise(rb_eArgError, "wrong number of arguments (given %d, expected 0..4)", argc);
    }

    return self;
}

static VALUE page_margins_top(VALUE self)
{
    plutobook_page_margins_t* margins = plutoprint_get_page_margins(self);
    return DBL2NUM((double)margins->top);
}

static VALUE page_margins_right(VALUE self)
{
    plutobook_page_margins_t* margins = plutoprint_get_page_margins(self);
    return DBL2NUM((double)margins->right);
}

static VALUE page_margins_bottom(VALUE self)
{
    plutobook_page_margins_t* margins = plutoprint_get_page_margins(self);
    return DBL2NUM((double)margins->bottom);
}

static VALUE page_margins_left(VALUE self)
{
    plutobook_page_margins_t* margins = plutoprint_get_page_margins(self);
    return DBL2NUM((double)margins->left);
}

static VALUE page_margins_eq(VALUE self, VALUE other)
{
    if (!rb_obj_is_kind_of(other, cPageMargins))
        return Qfalse;

    plutobook_page_margins_t* a = plutoprint_get_page_margins(self);
    plutobook_page_margins_t* b = plutoprint_get_page_margins(other);

    if (a->top == b->top && a->right == b->right &&
        a->bottom == b->bottom && a->left == b->left)
        return Qtrue;
    return Qfalse;
}

static VALUE make_page_margins_constant(float top, float right, float bottom, float left)
{
    VALUE obj = page_margins_alloc(cPageMargins);
    plutobook_page_margins_t* margins = plutoprint_get_page_margins(obj);
    margins->top = top;
    margins->right = right;
    margins->bottom = bottom;
    margins->left = left;
    return obj;
}

void Init_plutoprint_page_margins(void)
{
    cPageMargins = rb_define_class_under(mPlutoprint, "PageMargins", rb_cObject);
    rb_define_alloc_func(cPageMargins, page_margins_alloc);
    rb_define_method(cPageMargins, "initialize", page_margins_initialize, -1);
    rb_define_method(cPageMargins, "top", page_margins_top, 0);
    rb_define_method(cPageMargins, "right", page_margins_right, 0);
    rb_define_method(cPageMargins, "bottom", page_margins_bottom, 0);
    rb_define_method(cPageMargins, "left", page_margins_left, 0);
    rb_define_method(cPageMargins, "==", page_margins_eq, 1);

    /* Preset page margins constants */
    {
        plutobook_page_margins_t m;

        m = (plutobook_page_margins_t)PLUTOBOOK_PAGE_MARGINS_NONE;
        rb_define_const(mPlutoprint, "PAGE_MARGINS_NONE", make_page_margins_constant(m.top, m.right, m.bottom, m.left));

        m = (plutobook_page_margins_t)PLUTOBOOK_PAGE_MARGINS_NORMAL;
        rb_define_const(mPlutoprint, "PAGE_MARGINS_NORMAL", make_page_margins_constant(m.top, m.right, m.bottom, m.left));

        m = (plutobook_page_margins_t)PLUTOBOOK_PAGE_MARGINS_NARROW;
        rb_define_const(mPlutoprint, "PAGE_MARGINS_NARROW", make_page_margins_constant(m.top, m.right, m.bottom, m.left));

        m = (plutobook_page_margins_t)PLUTOBOOK_PAGE_MARGINS_MODERATE;
        rb_define_const(mPlutoprint, "PAGE_MARGINS_MODERATE", make_page_margins_constant(m.top, m.right, m.bottom, m.left));

        m = (plutobook_page_margins_t)PLUTOBOOK_PAGE_MARGINS_WIDE;
        rb_define_const(mPlutoprint, "PAGE_MARGINS_WIDE", make_page_margins_constant(m.top, m.right, m.bottom, m.left));
    }

    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_MARGINS_NONE")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_MARGINS_NORMAL")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_MARGINS_NARROW")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_MARGINS_MODERATE")));
    rb_obj_freeze(rb_const_get(mPlutoprint, rb_intern("PAGE_MARGINS_WIDE")));
}
