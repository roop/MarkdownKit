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

#ifndef __AST_H
#define __AST_H

#include <stddef.h>

/* struct ast_node: Abstract Syntax Tree node */
struct ast_node {
	const char *html_tag_name; // "p" for <p> tags
	size_t elem_offset;                    // offset of "<p>blah</p>" in parent node's text
	size_t close_tag_length;               // length of "</p>"
	size_t content_offset, content_length; // range of "blah" in parent node's text
	// void *additional_data;     // Arbitrary additional data
	struct ast_node *next;
	struct ast_node *children;
};

struct ast_node *ast_new_node(const char *html_tag_name, size_t elem_offset, struct ast_node *child);
struct ast_node *ast_last_node(struct ast_node *node);

#endif // __AST_H
