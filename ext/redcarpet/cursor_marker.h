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

#ifndef __CURSOR_MARKER_H
#define __CURSOR_MARKER_H

#include "buffer.h"

enum cursor_marker_status_t {
	CURSOR_MARKER_YET_TO_BE_INSERTED = 0,
	CURSOR_MARKER_IS_INSERTED = 1,
	CURSOR_MARKER_CANNOT_BE_INSERTED = 2,
	CURSOR_MARKER_SHOULD_NOT_BE_INSERTED = 3
};

int index_of_cursor(void *opaque, srcmap_t *srcmap, size_t len, size_t *effective_cursor_pos_index);
void rndr_cursor_marker(struct buf *ob, void *opaque, srcmap_t *srcmap, size_t len,
						size_t effective_cursor_pos_index);
int8_t is_cursor_in_range(void *opaque, srcmap_t *srcmap, size_t len);
void set_cursor_marker_status(void *opaque, enum cursor_marker_status_t status);

#endif // __CURSOR_MARKER_H

