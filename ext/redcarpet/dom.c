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

#include "dom.h"
#include <stdlib.h>
#include <stddef.h>

struct dom_node *dom_new_node(const char *html_tag_name, size_t elem_offset, struct dom_node *child)
{
	struct dom_node *dom_node = malloc(sizeof(struct dom_node));
	dom_node->html_tag_name = html_tag_name;
	dom_node->elem_offset = elem_offset;
	dom_node->close_tag_length = 0;
	dom_node->content_offset = 0;
	dom_node->content_length = 0;
	dom_node->next = 0;
	dom_node->children = child;
	return dom_node;
}

struct dom_node *dom_last_node(struct dom_node *node)
{
	if (node == 0) {
		return 0;
	}
	while (node->next) {
		node = node->next;
	}
	return node;
}
