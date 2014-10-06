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
#include "buffer.h"
#include <stdlib.h>
#include <stddef.h>
#include <stdio.h>

struct dom_node *dom_new_node(const char *html_tag_name, size_t elem_offset, struct dom_node *child)
{
	struct dom_node *dom_node = malloc(sizeof(struct dom_node));
	dom_node->html_tag_name = html_tag_name;
	dom_node->elem_offset = elem_offset;
	dom_node->close_tag_length = 0;
	dom_node->content_offset = 0;
	dom_node->content_length = 0;
	dom_node->raw_html_element_type = NOT_RAW_HTML;
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

struct dom_node* dom_last_open_raw_html_node(struct dom_node *dom_tree)
{
	if (!dom_tree)
		return 0;
	struct dom_node *last_node = dom_last_node(dom_tree);
	if (last_node->raw_html_element_type == UNCLOSED_RAW_HTML_ELEMENT) {
		struct dom_node *last_child = dom_last_open_raw_html_node(last_node->children);
		return (last_child? last_child : last_node);
	}
	return 0;
}

void dom_release(struct dom_node *dom)
{
	if (!dom)
		return;
	dom_release(dom->children);
	dom_release(dom->next);
	if (dom->raw_html_element_type != NOT_RAW_HTML) {
		// If raw html, the tag name is allocated (otherwise it's a static constant)
		free((void *) dom->html_tag_name);
	}
	free(dom);
}


static void print_in_one_line(const char *str, size_t len)
{
	if (len == 0) {
		return;
	}
	int is_ellipsis_printed = 0;
	for (int i = 0; i < len; i++) {
		if (i < 10 || (len - i) < 10) {
			char c = str[i];
			if (c == '\n') {
				printf("\\n");
			} else {
				printf("%c", str[i]);
			}
		} else if (!is_ellipsis_printed) {
			printf(" ... ");
			is_ellipsis_printed = 1;
		}
	}
}

#define USE_CONTENT_OFFSET

void dom_print(const struct dom_node *dom_node, const struct buf *buf, int depth, size_t offset)
{
	if (dom_node == 0) {
		return;
	}
	printf("%*s tag: [%s]", depth * 2, "", dom_node->html_tag_name);
	if (buf) {
#ifdef USE_CONTENT_OFFSET
		printf(" content: \"");
		size_t dom_offset = dom_node->content_offset;
		size_t dom_length = dom_node->content_length;
#else
		printf(" element: \"");
		size_t dom_offset = dom_node->elem_offset;
		size_t dom_length = dom_node->content_offset + dom_node->content_length + dom_node->close_tag_length - dom_offset;
#endif
		print_in_one_line((const char *) buf->data + offset + dom_offset, dom_length);
		printf("\"");
	}
	if (dom_node->raw_html_element_type) {
		printf(" (raw-html: %s)", (dom_node->raw_html_element_type == 1? "closed" : (dom_node->raw_html_element_type == 2? "unclosed" : "chunk")));
	}
	printf("\n");
	dom_print(dom_node->children, buf, depth + 1, offset + dom_node->content_offset);
	dom_print(dom_node->next, buf, depth, offset);
}
