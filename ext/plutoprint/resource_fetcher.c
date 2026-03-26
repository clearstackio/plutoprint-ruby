#include "plutoprint.h"

/* Singleton instance for DefaultResourceFetcher */
static VALUE default_resource_fetcher_instance = Qnil;

/* Resource fetch callback - calls Ruby fetch_url method */
plutobook_resource_data_t* plutoprint_resource_fetch_func(void* closure, const char* url)
{
    VALUE fetcher = (VALUE)closure;
    VALUE rb_url = rb_str_new_cstr(url);
    VALUE result = rb_funcall(fetcher, rb_intern("fetch_url"), 1, rb_url);

    if (NIL_P(result)) {
        return NULL;
    }

    if (!rb_obj_is_kind_of(result, cResourceData)) {
        return NULL;
    }

    plutoprint_resource_data_t* wrapper = plutoprint_get_resource_data(result);
    if (!wrapper->resource) {
        return NULL;
    }

    /* Increment reference count since plutobook will destroy it */
    return plutobook_resource_data_reference(wrapper->resource);
}

/* ResourceFetcher base class */

static VALUE resource_fetcher_fetch_url(VALUE self, VALUE url)
{
    Check_Type(url, T_STRING);
    plutobook_resource_data_t* resource = plutobook_fetch_url(StringValueCStr(url));
    if (!resource) {
        return Qnil;
    }

    /* Wrap the result in a ResourceData object */
    VALUE obj = rb_obj_alloc(cResourceData);
    plutoprint_resource_data_t* wrapper = plutoprint_get_resource_data(obj);

    /* Get the content and store it as a Ruby string */
    const char* content = plutobook_resource_data_get_content(resource);
    unsigned int content_length = plutobook_resource_data_get_content_length(resource);
    VALUE rb_content = rb_str_new(content, content_length);
    rb_str_freeze(rb_content);
    wrapper->content = rb_content;

    /* Reference the original resource */
    wrapper->resource = resource;

    return obj;
}

/* DefaultResourceFetcher */

static VALUE default_rf_set_ssl_cainfo(VALUE self, VALUE path)
{
    Check_Type(path, T_STRING);
    plutobook_set_ssl_cainfo(StringValueCStr(path));
    return self;
}

static VALUE default_rf_set_ssl_capath(VALUE self, VALUE path)
{
    Check_Type(path, T_STRING);
    plutobook_set_ssl_capath(StringValueCStr(path));
    return self;
}

static VALUE default_rf_set_ssl_verify_peer(VALUE self, VALUE verify)
{
    plutobook_set_ssl_verify_peer(RTEST(verify));
    return self;
}

static VALUE default_rf_set_ssl_verify_host(VALUE self, VALUE verify)
{
    plutobook_set_ssl_verify_host(RTEST(verify));
    return self;
}

static VALUE default_rf_set_http_follow_redirects(VALUE self, VALUE follow)
{
    plutobook_set_http_follow_redirects(RTEST(follow));
    return self;
}

static VALUE default_rf_set_http_max_redirects(VALUE self, VALUE amount)
{
    plutobook_set_http_max_redirects(NUM2INT(amount));
    return self;
}

static VALUE default_rf_set_http_timeout(VALUE self, VALUE timeout)
{
    plutobook_set_http_timeout(NUM2INT(timeout));
    return self;
}

/* Module function: Plutoprint.default_resource_fetcher */
static VALUE plutoprint_default_resource_fetcher(VALUE self)
{
    return default_resource_fetcher_instance;
}

void Init_plutoprint_resource_fetcher(void)
{
    /* ResourceFetcher base class */
    cResourceFetcher = rb_define_class_under(mPlutoprint, "ResourceFetcher", rb_cObject);
    rb_define_method(cResourceFetcher, "fetch_url", resource_fetcher_fetch_url, 1);

    /* DefaultResourceFetcher subclass */
    cDefaultResourceFetcher = rb_define_class_under(mPlutoprint, "DefaultResourceFetcher", cResourceFetcher);

    rb_define_method(cDefaultResourceFetcher, "set_ssl_cainfo", default_rf_set_ssl_cainfo, 1);
    rb_define_method(cDefaultResourceFetcher, "set_ssl_capath", default_rf_set_ssl_capath, 1);
    rb_define_method(cDefaultResourceFetcher, "set_ssl_verify_peer", default_rf_set_ssl_verify_peer, 1);
    rb_define_method(cDefaultResourceFetcher, "set_ssl_verify_host", default_rf_set_ssl_verify_host, 1);
    rb_define_method(cDefaultResourceFetcher, "set_http_follow_redirects", default_rf_set_http_follow_redirects, 1);
    rb_define_method(cDefaultResourceFetcher, "set_http_max_redirects", default_rf_set_http_max_redirects, 1);
    rb_define_method(cDefaultResourceFetcher, "set_http_timeout", default_rf_set_http_timeout, 1);

    /* Create the frozen singleton instance before undefining alloc */
    default_resource_fetcher_instance = rb_obj_alloc(cDefaultResourceFetcher);
    rb_obj_freeze(default_resource_fetcher_instance);
    rb_gc_register_mark_object(default_resource_fetcher_instance);

    /* Now prevent further instantiation */
    rb_undef_alloc_func(cDefaultResourceFetcher);

    /* Module function */
    rb_define_module_function(mPlutoprint, "default_resource_fetcher", plutoprint_default_resource_fetcher, 0);
}
