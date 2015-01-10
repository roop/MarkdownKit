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
#include "buffer.h"

enum raw_html_t {
	NOT_RAW_HTML = 0,
	CLOSED_RAW_HTML_ELEMENT = 1,
	UNCLOSED_RAW_HTML_ELEMENT = 2,
	RAW_HTML_BLOCK = 3,
	RAW_HTML_TAG = 4
};

enum ambiguous_html_state_t {
	NO_AMBIGUOUS_HTML = 0,
	CONTAINING_AMBIGUOUS_HTML = 1,
	FOLLOWED_BY_AMBIGUOUS_HTML = 2
};

/* struct ast_node: Abstract Syntax Tree node */
struct dom_node {              // Assuming "<tag><subtag></subtag><p>blah</p></tag>"

	const char *html_tag_name; // "p" for <p> tags

	// Positions in the output HTML string
	size_t elem_offset;        // invalid for raw_html // offset of "<p>blah</p>" in parent node's (i.e. "tag" 's) text
	size_t close_tag_length;   // invalid for raw_html // length of "</p>"
	size_t content_offset, content_length; // range of "blah" in parent node's (i.e. "tag" 's) text

	// Additional data for raw HTML tags
	enum raw_html_t raw_html_element_type;
	size_t raw_html_tag_end;
	enum ambiguous_html_state_t ambiguous_html_state;

	struct dom_node *next;
	struct dom_node *children;
};

struct dom_node *dom_new_node(const char *html_tag_name, size_t elem_offset, struct dom_node *child);
struct dom_node *dom_last_node(struct dom_node *node);
struct dom_node* dom_last_open_raw_html_node(struct dom_node *dom_tree);

void dom_release(struct dom_node *dom);
void dom_print(const struct dom_node *dom_node, const struct buf *buf, int depth, size_t offset);

#endif // __DOM_H
