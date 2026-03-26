#include "plutoprint.h"

static void resource_data_mark(void* data)
{
    plutoprint_resource_data_t* wrapper = (plutoprint_resource_data_t*)data;
    rb_gc_mark(wrapper->content);
}

static void resource_data_dfree(void* data)
{
    plutoprint_resource_data_t* wrapper = (plutoprint_resource_data_t*)data;
    if (wrapper->resource) {
        plutobook_resource_data_destroy(wrapper->resource);
        wrapper->resource = NULL;
    }
    xfree(wrapper);
}

static size_t resource_data_memsize(const void* data)
{
    return sizeof(plutoprint_resource_data_t);
}

const rb_data_type_t plutoprint_resource_data_type = {
    "Plutoprint::ResourceData",
    { resource_data_mark, resource_data_dfree, resource_data_memsize },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

plutoprint_resource_data_t* plutoprint_get_resource_data(VALUE obj)
{
    plutoprint_resource_data_t* wrapper;
    TypedData_Get_Struct(obj, plutoprint_resource_data_t, &plutoprint_resource_data_type, wrapper);
    return wrapper;
}

static VALUE resource_data_alloc(VALUE klass)
{
    plutoprint_resource_data_t* wrapper;
    VALUE obj = TypedData_Make_Struct(klass, plutoprint_resource_data_t, &plutoprint_resource_data_type, wrapper);
    wrapper->resource = NULL;
    wrapper->content = Qnil;
    return obj;
}

static VALUE resource_data_initialize(int argc, VALUE* argv, VALUE self)
{
    plutoprint_resource_data_t* wrapper;
    TypedData_Get_Struct(self, plutoprint_resource_data_t, &plutoprint_resource_data_type, wrapper);

    VALUE content, mime_type, text_encoding;
    rb_scan_args(argc, argv, "12", &content, &mime_type, &text_encoding);
    Check_Type(content, T_STRING);

    /* Duplicate and freeze the content string */
    content = rb_str_dup(content);
    rb_str_freeze(content);
    wrapper->content = content;

    const char* mime = NIL_P(mime_type) ? "" : StringValueCStr(mime_type);
    const char* enc = NIL_P(text_encoding) ? "" : StringValueCStr(text_encoding);

    /* Use create_without_copy since we hold the content in Ruby and prevent GC via mark */
    wrapper->resource = plutobook_resource_data_create_without_copy(
        RSTRING_PTR(content), (unsigned int)RSTRING_LEN(content),
        mime, enc, NULL, NULL);
    if (!wrapper->resource) {
        rb_raise(ePlutoprintError, "%s", plutobook_get_error_message());
    }

    return self;
}

static VALUE resource_data_content(VALUE self)
{
    plutoprint_resource_data_t* wrapper = plutoprint_get_resource_data(self);
    return wrapper->content;
}

static VALUE resource_data_mime_type(VALUE self)
{
    plutoprint_resource_data_t* wrapper = plutoprint_get_resource_data(self);
    if (!wrapper->resource) return Qnil;
    const char* mime = plutobook_resource_data_get_mime_type(wrapper->resource);
    return rb_str_new_cstr(mime ? mime : "");
}

static VALUE resource_data_text_encoding(VALUE self)
{
    plutoprint_resource_data_t* wrapper = plutoprint_get_resource_data(self);
    if (!wrapper->resource) return Qnil;
    const char* enc = plutobook_resource_data_get_text_encoding(wrapper->resource);
    return rb_str_new_cstr(enc ? enc : "");
}

void Init_plutoprint_resource_data(void)
{
    cResourceData = rb_define_class_under(mPlutoprint, "ResourceData", rb_cObject);
    rb_define_alloc_func(cResourceData, resource_data_alloc);
    rb_define_method(cResourceData, "initialize", resource_data_initialize, -1);
    rb_define_method(cResourceData, "content", resource_data_content, 0);
    rb_define_method(cResourceData, "mime_type", resource_data_mime_type, 0);
    rb_define_method(cResourceData, "text_encoding", resource_data_text_encoding, 0);
}
