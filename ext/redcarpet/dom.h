/*
 * Copyright (c) 2014, Roopesh Chander
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#ifndef __DOM_H
#define __DOM_H

#include <stddef.h>

enum raw_html_t {
	NOT_RAW_HTML = 0,
	CLOSED_RAW_HTML_ELEMENT = 1,
	UNCLOSED_RAW_HTML_ELEMENT = 2,
	UNMATCHED_RAW_HTML_END_TAG = 3,
	MALFORMED_RAW_HTML_TAG = 4,
};

/* struct ast_node: Abstract Syntax Tree node */
struct dom_node {              // Assuming "<tag><subtag></subtag><p>blah</p></tag>"
	const char *html_tag_name; // "p" for <p> tags
	size_t elem_offset;        // invalid for raw_html // offset of "<p>blah</p>" in parent node's (i.e. "tag" 's) text
	size_t close_tag_length;   // invalid for raw_html // length of "</p>"
	size_t content_offset, content_length; // range of "blah" in parent node's (i.e. "tag" 's) text
	enum raw_html_t raw_html_element_type;
	// void *additional_data;     // Arbitrary additional data
	struct dom_node *next;
	struct dom_node *children;
};

struct dom_node *dom_new_node(const char *html_tag_name, size_t elem_offset, struct dom_node *child);
struct dom_node *dom_last_node(struct dom_node *node);
struct dom_node* dom_last_open_raw_html_node(struct dom_node *dom_tree);

#endif // __DOM_H