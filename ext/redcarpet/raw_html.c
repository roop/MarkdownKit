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

#include "raw_html.h"
#include "dom.h"
#include "buffer.h"
#include "shl.h"
#include "cursor_marker.h"
#include "streamhtmlparser/src/streamhtmlparser/htmlparser.h"
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

#define STACK_SIZE 32

struct callback_ctx {
	struct buf *ob;
	struct dom_node *dom;
	int is_within_tag_or_comment;
	size_t pos;
	int is_pos_valid;
	size_t tag_start_pos;
	size_t prev_tag_end_pos;
	const char *data;
	srcmap_t *srcmap;
	void *shl;
	void *opaque;

	size_t stack[STACK_SIZE]; // offsets
	unsigned int stack_depth;
};

static inline const char *newstr(const char *src)
{
	char *dst = malloc(strlen(src) * sizeof(char));
	return strcpy(dst, src);
}

static int indexOfStringInSortedList(const char *str, const char *list[], int offset, int length)
{
	if (length <= 0) {
		return -1;
	}
	int mid = (offset + length / 2);
	int cmp = strcasecmp(str, list[mid]);
	if (cmp < 0) {
		return indexOfStringInSortedList(str, list, offset, mid - offset);
	} else if (cmp > 0) {
		return indexOfStringInSortedList(str, list, mid + 1, offset + length - mid - 1);
	}
	assert(cmp == 0);
	return mid;
}

static int isVoidHtmlElement(const char *tagName)
{
	static const char *voidHtmlElementsList[] = {
		"area", "base",  "br",     "col",    "embed",
		"hr",   "img",   "input",  "keygen", "link",
		"meta", "param", "source", "track",  "wbr"
	};
	int i = indexOfStringInSortedList(tagName, voidHtmlElementsList, 0, 15);
	return (i >= 0? 1 : 0);
}

static void dom_append_raw_html_node(struct dom_node *dom_tree, struct dom_node *node)
{
	assert(dom_tree != 0);
	assert(node->raw_html_element_type > 0);
	struct dom_node *last_node = dom_last_node(dom_tree);
	assert(last_node->next == 0);
	if (last_node->raw_html_element_type == UNCLOSED_RAW_HTML_ELEMENT) {
		if (last_node->children == 0) {
			last_node->children = node;
		} else {
			dom_append_raw_html_node(last_node->children, node);
		}
	} else {
		last_node->next = node;
	}
}

#define START_TAG 1
#define END_TAG 2

static void htmlTagIdentified(const struct callback_ctx *ctx, size_t tag_end_pos, int start_or_end_tag,
							  size_t *start_of_tag_in_ob, size_t *end_of_tag_in_ob)
{
	size_t text_start_pos = ctx->prev_tag_end_pos;
	size_t tag_start_pos = ctx->tag_start_pos;
	size_t text_size = (tag_start_pos - text_start_pos);

	// Handle the text before the HTML tag

	if (text_size) {
		shl_apply_syntax_formatting_with_srcmap(ctx->shl, ctx->srcmap + text_start_pos, text_size,
												SHL_RAW_HTML_BLOCK_TEXT_CONTENT);
		size_t effective_cursor_pos_index = 0;
		int ci = index_of_cursor(ctx->opaque, ctx->srcmap + text_start_pos, text_size, &effective_cursor_pos_index);
		if (ci >= 0) { // Cursor is contained in this text
			assert(ci <= text_size);
			if (ci > 0)
				bufput(ctx->ob, ctx->data + text_start_pos, ci);
			rndr_cursor_marker(ctx->ob, ctx->opaque, ctx->srcmap + text_start_pos, text_size, effective_cursor_pos_index);
			if (text_size > ci)
				bufput(ctx->ob, ctx->data + text_start_pos + ci, text_size - ci);
		} else { // Cursor is NOT contained in this text
			bufput(ctx->ob, ctx->data + text_start_pos, text_size);
		}
	}

	// Handle the HTML tag itself

	size_t tag_size = (tag_end_pos - tag_start_pos);
	if (tag_size) {
		shl_apply_syntax_formatting_with_srcmap(ctx->shl, ctx->srcmap + tag_start_pos, tag_size,
												SHL_RAW_HTML_TAG);
		if (start_or_end_tag == END_TAG) { // If end-tag, add cursor before the tag
			rndr_cursor_marker(ctx->ob, ctx->opaque, ctx->srcmap + tag_start_pos, tag_size, 0);
		}
		(*start_of_tag_in_ob) = ctx->ob->size;
		bufput(ctx->ob, ctx->data + tag_start_pos, tag_size);
		(*end_of_tag_in_ob) = ctx->ob->size;
		if (start_or_end_tag == START_TAG) { // If start-tag, add cursor after the tag
			rndr_cursor_marker(ctx->ob, ctx->opaque, ctx->srcmap + tag_start_pos, tag_size, tag_size - 1);
		}
	} else {
		(*start_of_tag_in_ob) = ctx->ob->size;
		(*end_of_tag_in_ob) = ctx->ob->size;
	}
}

static void onEnteringPossibleTagOrComment(void *context)
{
	struct callback_ctx *ctx = context;
	ctx->is_within_tag_or_comment = 1;
	assert(ctx->is_pos_valid);
	ctx->tag_start_pos = ctx->pos;
}

static void onIdentifyingStartOrSelfClosingTag(const char *tagName, void *context)
{
	struct callback_ctx *ctx = context;
	assert(ctx->is_pos_valid);

	size_t start_of_tag, end_of_tag;
	htmlTagIdentified(ctx, ctx->pos + 1, START_TAG, &start_of_tag, &end_of_tag);

	size_t end_of_containing_elem_tag = ((ctx->stack_depth > 0) ? ctx->stack[ctx->stack_depth - 1] : 0);
	size_t eo = (start_of_tag - end_of_containing_elem_tag);
	size_t co = (end_of_tag - end_of_containing_elem_tag);
	struct dom_node *dom_node = dom_new_node(newstr(tagName), eo, 0);
	if (isVoidHtmlElement(tagName)) {
		dom_node->raw_html_element_type = CLOSED_RAW_HTML_ELEMENT;
	} else {
		dom_node->raw_html_element_type = UNCLOSED_RAW_HTML_ELEMENT;
		dom_node->content_offset = co;
		if (ctx->stack_depth < STACK_SIZE) {
			ctx->stack[ctx->stack_depth] = end_of_tag;
			ctx->stack_depth++;
		}
		// FIXME: Handle the case when stack depth is exeeded
	}

	if (ctx->dom == 0) {
		ctx->dom = dom_node;
	} else {
		dom_append_raw_html_node(ctx->dom, dom_node);
	}

	ctx->is_within_tag_or_comment = 0;
	ctx->prev_tag_end_pos = ctx->pos + 1;
}

static void onIdentifyingEndTag(const char *tagName, void *context)
{
	struct callback_ctx *ctx = context;
	assert(ctx->is_pos_valid);

	size_t start_of_tag, end_of_tag;
	htmlTagIdentified(ctx, ctx->pos + 1, END_TAG, &start_of_tag, &end_of_tag);

	struct dom_node *open_raw_html_node = (ctx->dom ? dom_last_open_raw_html_node(ctx->dom) : 0);
	if (open_raw_html_node && (strcasecmp(open_raw_html_node->html_tag_name, tagName) == 0)) {
		assert(ctx->stack_depth > 0);
		open_raw_html_node->raw_html_element_type = CLOSED_RAW_HTML_ELEMENT;
		open_raw_html_node->content_length = start_of_tag - ctx->stack[ctx->stack_depth - 1];
		open_raw_html_node->close_tag_length = end_of_tag - start_of_tag;
		ctx->stack_depth--;
	} else {
		size_t end_of_containing_elem_tag = ((ctx->stack_depth > 0) ? ctx->stack[ctx->stack_depth - 1] : 0);
		size_t eo = (start_of_tag - end_of_containing_elem_tag);
		struct dom_node *dom_node = dom_new_node(newstr(tagName), eo, 0);
		dom_node->raw_html_element_type = UNMATCHED_RAW_HTML_END_TAG;
		if (ctx->dom == 0) {
			ctx->dom = dom_node;
		} else {
			dom_append_raw_html_node(ctx->dom, dom_node);
		}
	}

	ctx->is_within_tag_or_comment = 0;
	ctx->prev_tag_end_pos = ctx->pos + 1;
}

static void onIdentifyingAsComment(void *context)
{
	struct callback_ctx *ctx = context;
	ctx->is_within_tag_or_comment = 0;
	ctx->prev_tag_end_pos = ctx->pos + 1;
	// FIXME: Comments left unhandled
}

static void onIdentifyingAsNotATagOrComment(void *context)
{
	struct callback_ctx *ctx = context;
	ctx->is_within_tag_or_comment = 0;
}

void add_raw_html(struct buf *ob, const char *data, size_t size, srcmap_t *srcmap, void *shl, void *opaque)
{
	struct htmlparser_ctx_s *parser = htmlparser_new();
	struct callback_ctx callback_context;
	callback_context.ob = ob;
	callback_context.dom = 0;
	callback_context.is_within_tag_or_comment = 0;
	callback_context.stack_depth = 0;
	callback_context.prev_tag_end_pos = 0;
	callback_context.data = data;
	callback_context.srcmap = srcmap;
	callback_context.shl = shl;
	callback_context.opaque = opaque;
	parser->callback_context = &callback_context;
	parser->on_enter_possible_tag_or_comment = &onEnteringPossibleTagOrComment;
	parser->on_exit_start_tag = &onIdentifyingStartOrSelfClosingTag;
	parser->on_exit_end_tag = &onIdentifyingEndTag;
	parser->on_exit_empty_tag = &onIdentifyingStartOrSelfClosingTag;
	parser->on_exit_comment = &onIdentifyingAsComment;
	parser->on_cancel_possible_tag_or_comment = &onIdentifyingAsNotATagOrComment;
	htmlparser_reset(parser);

	int i = 0, prev = 0;
	for (i = 0; i < size; i++) {
		const char c = data[i];
		if (c == '<' || c == '>') {
			if (prev < i) {
				htmlparser_parse(parser, data + prev, (int) (i - prev));
			}
			callback_context.pos = i;
			callback_context.is_pos_valid = 1;
			htmlparser_parse(parser, data + i, 1);
			prev = i + 1;
			callback_context.is_pos_valid = 0;
		}
	}
	if (prev < i) {
		htmlparser_parse(parser, data + prev, (int) (size - prev));
	}

	htmlparser_delete(parser);

	if (callback_context.is_within_tag_or_comment) {
		// Redcarpet probably ended the HTML tag prematurely
		// (Like on: `<tag attr=">" >`)
		struct dom_node *dom_node = dom_new_node(0, ob->size, 0);
		dom_node->raw_html_element_type = MALFORMED_RAW_HTML_TAG;
		if (callback_context.dom == 0) {
			callback_context.dom = dom_node;
		} else {
			dom_append_raw_html_node(callback_context.dom, dom_node);
		}
		size_t start_of_tag, end_of_tag;
		htmlTagIdentified(&callback_context, size, END_TAG, &start_of_tag, &end_of_tag); // Incomplete tag
		callback_context.is_within_tag_or_comment = 0;
		callback_context.prev_tag_end_pos = size;
	}

	assert(callback_context.is_within_tag_or_comment == 0);
	callback_context.tag_start_pos = size;
	size_t start_of_tag, end_of_tag;
	htmlTagIdentified(&callback_context, size, END_TAG, &start_of_tag, &end_of_tag); // Trailing text, if any

	if (callback_context.dom) {
		buf_append_dom_node(ob, callback_context.dom);
	}
}
