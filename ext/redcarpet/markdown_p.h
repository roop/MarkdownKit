//
//  markdown_p.h
//  Bisect
//
//  Created by Roopesh Chander on 10/04/15.
//  Copyright (c) 2015 Roopesh Chander. All rights reserved.
//

#ifndef MARKDOWN_P_H__
#define MARKDOWN_P_H__

#include "buffer.h"
#include "stack.h"

#define REF_TABLE_SIZE 8

/*************************
 * Internally-used types *
 *************************/

/* link_ref: reference to a link */
struct link_ref {
    unsigned int id;

    struct buf *link;
    struct buf *title;

    struct link_ref *next;
};

/* footnote_ref: reference to a footnote */
struct footnote_ref {
    unsigned int id;

    int is_used;
    unsigned int num;

    struct buf *contents;
};

/* footnote_item: an item in a footnote_list */
struct footnote_item {
    struct footnote_ref *ref;
    struct footnote_item *next;
};

/* footnote_list: linked list of footnote_item */
struct footnote_list {
    unsigned int count;
    struct footnote_item *head;
    struct footnote_item *tail;
};

/* render • structure containing one particular render */
struct sd_markdown {
    struct sd_callbacks	cb;
    void *opaque;

    struct link_ref *refs[REF_TABLE_SIZE];
    struct footnote_list footnotes_found;
    struct footnote_list footnotes_used;
    uint8_t active_char[256];
    struct stack work_bufs[2];
    unsigned int ext_flags;
    size_t max_nesting;
    int in_link_body;

    void *shl; /* Used for sending syntax highlight data to Obj-C */
};

#endif // MARKDOWN_P_H__
