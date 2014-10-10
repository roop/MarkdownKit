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

void add_raw_html_tag(struct buf *ob, const char *data, size_t size, srcmap_t *srcmap, void *shl, void *opaque)
{
	shl_apply_syntax_formatting_with_srcmap(shl, srcmap, size, SHL_RAW_HTML_TAG);
	struct dom_node *dom_node = dom_new_node(0, ob->size, 0);
	dom_node->raw_html_element_type = RAW_HTML_TAG;
	dom_node->content_offset = ob->size;
	buf_append_dom_node(ob, dom_node);
	bufput(ob, data, size);
	ob->dom->ambiguous_html_state = CONTAINING_AMBIGUOUS_HTML;
	if (is_cursor_in_range(opaque, srcmap, size)) {
		// If cursor is inside the html tag
		set_cursor_marker_status(opaque, CURSOR_MARKER_CANNOT_BE_INSERTED);
	}
}

struct callback_ctx {
	struct buf *ob;
	struct dom_node *dom;
	int is_raw_html_block;
	int is_within_tag_or_comment;
	size_t pos;
	int is_pos_valid;
	size_t tag_start_pos;
	size_t prev_tag_end_pos;
	const char *data;
	srcmap_t *srcmap;
	void *shl;
	void *opaque;

	int potentially_invalid_html_found;
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

enum html_tag_type_t {
	HTML_START_TAG,
	HTML_END_TAG,
	HTML_COMMENT
};

static void htmlTagIdentified(const struct callback_ctx *ctx, size_t tag_end_pos, enum html_tag_type_t tag_type,
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
												((tag_type == HTML_COMMENT)? SHL_RAW_HTML_COMMENT : SHL_RAW_HTML_TAG));
		if (tag_type == HTML_END_TAG || tag_type == HTML_COMMENT) { // If end-tag, add cursor before the tag
			rndr_cursor_marker(ctx->ob, ctx->opaque, ctx->srcmap + tag_start_pos, tag_size, 0);
		}
		(*start_of_tag_in_ob) = ctx->ob->size;
		bufput(ctx->ob, ctx->data + tag_start_pos, tag_size);
		(*end_of_tag_in_ob) = ctx->ob->size;
		if (tag_type == HTML_START_TAG) { // If start-tag, add cursor after the tag
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
	htmlTagIdentified(ctx, ctx->pos + 1, HTML_START_TAG, &start_of_tag, &end_of_tag);

	struct dom_node *open_raw_html_node = (ctx->dom ? dom_last_open_raw_html_node(ctx->dom) : 0);
	size_t end_of_containing_elem_tag = (open_raw_html_node ? open_raw_html_node->raw_html_tag_end : 0);
	size_t eo = (start_of_tag - end_of_containing_elem_tag);
	size_t co = (end_of_tag - end_of_containing_elem_tag);
	struct dom_node *dom_node = dom_new_node(newstr(tagName), eo, 0);
	if (isVoidHtmlElement(tagName)) {
		dom_node->raw_html_element_type = CLOSED_RAW_HTML_ELEMENT;
	} else {
		dom_node->raw_html_element_type = UNCLOSED_RAW_HTML_ELEMENT;
		dom_node->content_offset = co;
		dom_node->raw_html_tag_end = end_of_tag;
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
	htmlTagIdentified(ctx, ctx->pos + 1, HTML_END_TAG, &start_of_tag, &end_of_tag);

	struct dom_node *open_raw_html_node = (ctx->dom ? dom_last_open_raw_html_node(ctx->dom) : 0);
	if (open_raw_html_node && (strcasecmp(open_raw_html_node->html_tag_name, tagName) == 0)) {
		assert(open_raw_html_node->raw_html_element_type == UNCLOSED_RAW_HTML_ELEMENT);
		open_raw_html_node->raw_html_element_type = CLOSED_RAW_HTML_ELEMENT;
		open_raw_html_node->content_length = start_of_tag - open_raw_html_node->raw_html_tag_end;
		open_raw_html_node->close_tag_length = end_of_tag - start_of_tag;
	} else {
		ctx->potentially_invalid_html_found = 1;
	}

	ctx->is_within_tag_or_comment = 0;
	ctx->prev_tag_end_pos = ctx->pos + 1;
}

static void onIdentifyingAsComment(void *context)
{
	struct callback_ctx *ctx = context;

	// Add comment text to ob; no need to add to the DOM
	size_t start_of_tag, end_of_tag;
	htmlTagIdentified(ctx, ctx->pos + 1, HTML_COMMENT, &start_of_tag, &end_of_tag);

	ctx->is_within_tag_or_comment = 0;
	ctx->prev_tag_end_pos = ctx->pos + 1;
}

static void onIdentifyingAsNotATagOrComment(void *context)
{
	struct callback_ctx *ctx = context;
	ctx->is_within_tag_or_comment = 0;
	ctx->potentially_invalid_html_found = 1;
}

void add_raw_html_block(struct buf *ob, const char *data, size_t size, srcmap_t *srcmap, void *shl, void *opaque)
{
	struct htmlparser_ctx_s *parser = htmlparser_new();
	struct callback_ctx callback_context;
	callback_context.ob = ob;
	callback_context.dom = 0;
	callback_context.is_within_tag_or_comment = 0;
	callback_context.prev_tag_end_pos = 0;
	callback_context.data = data;
	callback_context.srcmap = srcmap;
	callback_context.shl = shl;
	callback_context.opaque = opaque;
	callback_context.potentially_invalid_html_found = 0;
	parser->callback_context = &callback_context;
	parser->on_enter_possible_tag_or_comment = &onEnteringPossibleTagOrComment;
	parser->on_exit_start_tag = &onIdentifyingStartOrSelfClosingTag;
	parser->on_exit_end_tag = &onIdentifyingEndTag;
	parser->on_exit_empty_tag = &onIdentifyingStartOrSelfClosingTag;
	parser->on_exit_comment = &onIdentifyingAsComment;
	parser->on_cancel_possible_tag_or_comment = &onIdentifyingAsNotATagOrComment;
	htmlparser_reset(parser);

	size_t initial_ob_size = ob->size;

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
			if (callback_context.potentially_invalid_html_found) {
				break;
			}
		}
	}

	htmlparser_delete(parser);

	if (callback_context.potentially_invalid_html_found || // Potentially invalid HTML in block
		callback_context.is_within_tag_or_comment       || // Incomplete tag (E.g.: `<tag attr=">" >`)
		(callback_context.prev_tag_end_pos < size)) {      // Trailing text (E.g.: `</tag> blah`)
		// It's not safe to trust the DOM we have generated from this HTML block.
		// So let's discard it and treat the whole block as a single chunk.
		if (callback_context.prev_tag_end_pos < size) {
			// Mark unidentified stuff as text content
			shl_apply_syntax_formatting_with_srcmap(shl, srcmap + callback_context.prev_tag_end_pos,
													(size - callback_context.prev_tag_end_pos),
													SHL_RAW_HTML_BLOCK_TEXT_CONTENT);
		}
		dom_release(callback_context.dom); // Discard the DOM tree we've built
		ob->size = initial_ob_size; // Remove any text added to ob
		struct dom_node *dom_node = dom_new_node(0, ob->size, 0);
		dom_node->raw_html_element_type = RAW_HTML_BLOCK;
		dom_node->content_offset = ob->size;
		dom_node->content_length = size;
		dom_node->ambiguous_html_state = CONTAINING_AMBIGUOUS_HTML;
		buf_append_dom_node(ob, dom_node); // Add chunk node as DOM tree
		bufput(ob, data, size); // Write the text as-is to ob
		if (is_cursor_in_range(opaque, srcmap, size)) {
			// If cursor is inside the raw html block
			set_cursor_marker_status(opaque, CURSOR_MARKER_CANNOT_BE_INSERTED);
		}
	} else if (callback_context.dom) {
		// We have a good DOM
		if (dom_last_open_raw_html_node(callback_context.dom)) {
			callback_context.dom->ambiguous_html_state = CONTAINING_AMBIGUOUS_HTML;
		}
		buf_append_dom_node(ob, callback_context.dom);
	}
}
