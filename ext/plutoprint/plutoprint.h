#ifndef PLUTOPRINT_H
#define PLUTOPRINT_H

#include <ruby.h>
#include <plutobook.h>

/* Module and class declarations */
extern VALUE mPlutoprint;
extern VALUE ePlutoprintError;
extern VALUE cPageSize;
extern VALUE cPageMargins;
extern VALUE cCanvas;
extern VALUE cImageCanvas;
extern VALUE cPDFCanvas;
extern VALUE cBook;
extern VALUE cResourceData;
extern VALUE cResourceFetcher;
extern VALUE cDefaultResourceFetcher;

/* TypedData type structs */
extern const rb_data_type_t plutoprint_page_size_type;
extern const rb_data_type_t plutoprint_page_margins_type;
extern const rb_data_type_t plutoprint_canvas_type;
extern const rb_data_type_t plutoprint_book_type;
extern const rb_data_type_t plutoprint_resource_data_type;

/* Resource data wrapper */
typedef struct {
    plutobook_resource_data_t* resource;
    VALUE content;
} plutoprint_resource_data_t;

/* Helper functions */
plutobook_page_size_t plutoprint_create_page_size(VALUE obj);
plutobook_page_size_t* plutoprint_get_page_size(VALUE obj);
plutobook_page_margins_t plutoprint_create_page_margins(VALUE obj);
plutobook_page_margins_t* plutoprint_get_page_margins(VALUE obj);
plutobook_canvas_t* plutoprint_get_canvas(VALUE obj);
plutoprint_resource_data_t* plutoprint_get_resource_data(VALUE obj);

/* Stream write callback */
plutobook_stream_status_t plutoprint_stream_write_callback(void* closure, const char* data, unsigned int length);

/* Resource fetch callback */
plutobook_resource_data_t* plutoprint_resource_fetch_func(void* closure, const char* url);

/* Init functions for sub-files */
void Init_plutoprint_page_size(void);
void Init_plutoprint_page_margins(void);
void Init_plutoprint_canvas(void);
void Init_plutoprint_book(void);
void Init_plutoprint_resource_data(void);
void Init_plutoprint_resource_fetcher(void);

#endif /* PLUTOPRINT_H */
