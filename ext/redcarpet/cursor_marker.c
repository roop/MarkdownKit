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

#include "cursor_marker.h"
#include "html.h"

int index_of_cursor(void *opaque, srcmap_t *srcmap, size_t len, size_t *effective_cursor_pos_index)
{
	struct html_renderopt *render_options = opaque;
	int should_insert_cursor_marker = (render_options->cursor_marker_status == CURSOR_MARKER_YET_TO_BE_INSERTED);
	size_t cursor_pos = render_options->cursor_pos;
	if (srcmap && should_insert_cursor_marker) {
		while (len > 0 && srcmap[len - 1] < 0) len--;
		if (len == 0) {
			return -1;
		}
		if ((srcmap[0] <= cursor_pos) && (srcmap[len - 1] >= cursor_pos)) {
			for (int i = 0; i < len; i++) {
				if (srcmap[i] >= 0 && srcmap[i] >= cursor_pos) {
					if (effective_cursor_pos_index) {
						(*effective_cursor_pos_index) = i;
					}
					return i;
				}
			}
		} else if (srcmap[len - 1] + 1 == cursor_pos) {
			if (effective_cursor_pos_index) {
				(*effective_cursor_pos_index) = len - 1;
			}
			return (int) len;
		}
	}
	return -1;
}

void rndr_cursor_marker(struct buf *ob, void *opaque, srcmap_t *srcmap, size_t len,
                        size_t effective_cursor_pos_index)
{
	struct html_renderopt *render_options = opaque;
	if (render_options->cursor_marker_status == CURSOR_MARKER_YET_TO_BE_INSERTED) {
		while (len > 0 && srcmap[len - 1] < 0) len--;
		if ((srcmap[0] <= render_options->cursor_pos) && (len > 0 && srcmap[len - 1] + 1 >= render_options->cursor_pos)) {
			BUFPUTSL(ob, "<span id=\"__cursor_marker__\"></span>");
			render_options->cursor_marker_status = CURSOR_MARKER_IS_INSERTED;
			render_options->effective_cursor_pos = srcmap[effective_cursor_pos_index];
		}
	}
}

void set_cursor_marker_status(void *opaque, enum cursor_marker_status_t status)
{
	struct html_renderopt *render_options = opaque;
	render_options->cursor_marker_status = status;
}
