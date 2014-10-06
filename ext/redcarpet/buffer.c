/*
 * Copyright (c) 2008, Natacha Porté
 * Copyright (c) 2011, Vicent Martí
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

#define BUFFER_MAX_ALLOC_SIZE (1024 * 1024 * 16) //16mb

#include "buffer.h"
#include "dom.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

/* MSVC compat */
#if defined(_MSC_VER)
#	define _buf_vsnprintf _vsnprintf
#else
#	define _buf_vsnprintf vsnprintf
#endif

int
bufprefix(const struct buf *buf, const char *prefix)
{
	size_t i;
	assert(buf && buf->unit);

	for (i = 0; i < buf->size; ++i) {
		if (prefix[i] == 0)
			return 0;

		if (buf->data[i] != prefix[i])
			return buf->data[i] - prefix[i];
	}

	return 0;
}

/* bufgrow: increasing the allocated size to the given value */
int
bufgrow(struct buf *buf, size_t neosz)
{
	size_t neoasz;
	void *neodata;

	assert(buf && buf->unit);

	if (neosz > BUFFER_MAX_ALLOC_SIZE)
		return BUF_ENOMEM;

	if (buf->asize >= neosz)
		return BUF_OK;

	neoasz = buf->asize + buf->unit;
	while (neoasz < neosz)
		neoasz += buf->unit;

	neodata = realloc(buf->data, neoasz);
	if (!neodata)
		return BUF_ENOMEM;

	buf->data = neodata;

	if (buf->is_srcmap_enabled) {
		buf->srcmap = realloc(buf->srcmap, neoasz * sizeof(srcmap_t));
		if (!buf->srcmap) {
			return BUF_ENOMEM;
		}
		// Init unassigned bytes in the srcmap to -1 (which indicates
		// that the byte cannot be mapped to the Markdown source)
		for (size_t i = buf->asize; i < neoasz; i++) {
			buf->srcmap[i] = -1;
		}
	}

	buf->asize = neoasz;
	return BUF_OK;
}


/* bufnew: allocation of a new buffer */
struct buf *
bufnew(size_t unit)
{
	struct buf *ret;
	ret = malloc(sizeof (struct buf));

	if (ret) {
		ret->data = 0;
		ret->size = ret->asize = 0;
		ret->unit = unit;
		ret->is_srcmap_enabled = 0;
		ret->srcmap = 0;
		ret->dom = 0;
	}
	return ret;
}

struct buf *
bufnewsm(size_t unit)
{
	struct buf *ret;
	ret = bufnew(unit);

	if (ret) {
		ret->is_srcmap_enabled = 1;
	}
	return ret;
}

/* bufnullterm: NULL-termination of the string array */
const char *
bufcstr(struct buf *buf)
{
	assert(buf && buf->unit);

	if (buf->size < buf->asize && buf->data[buf->size] == 0)
		return (char *)buf->data;

	if (buf->size + 1 <= buf->asize || bufgrow(buf, buf->size + 1) == 0) {
		buf->data[buf->size] = 0;
		return (char *)buf->data;
	}

	return NULL;
}

/* bufprintf: formatted printing to a buffer */
void
bufprintf(struct buf *buf, const char *fmt, ...)
{
	va_list ap;
	int n;

	assert(buf && buf->unit);

	if (buf->size >= buf->asize && bufgrow(buf, buf->size + 1) < 0)
		return;

	va_start(ap, fmt);
	n = _buf_vsnprintf((char *)buf->data + buf->size, buf->asize - buf->size, fmt, ap);
	va_end(ap);

	if (n < 0) {
#ifdef _MSC_VER
		va_start(ap, fmt);
		n = _vscprintf(fmt, ap);
		va_end(ap);
#else
		return;
#endif
	}

	if ((size_t)n >= buf->asize - buf->size) {
		if (bufgrow(buf, buf->size + n + 1) < 0)
			return;

		va_start(ap, fmt);
		n = _buf_vsnprintf((char *)buf->data + buf->size, buf->asize - buf->size, fmt, ap);
		va_end(ap);
	}

	if (n < 0)
		return;

	buf->size += n;
}

/* bufput: appends raw data to a buffer */
void
bufputsm(struct buf *buf, const void *data, const srcmap_t *srcmap, size_t offset, size_t len)
{
	assert(buf && buf->unit);

	if (buf->size + len > buf->asize && bufgrow(buf, buf->size + len) < 0)
		return;

	memcpy(buf->data + buf->size, data + offset, len);
	if (srcmap && buf->srcmap)
		memcpy(buf->srcmap + buf->size, srcmap + offset, len * sizeof(srcmap_t));

	buf->size += len;
}

void
bufput(struct buf *buf, const void *data, size_t len)
{
	bufputsm(buf, data, (const srcmap_t *) 0, (size_t) 0, len);
}

/* bufputs: appends a NUL-terminated string to a buffer */
void
bufputs(struct buf *buf, const char *str)
{
	bufput(buf, str, strlen(str));
}


/* bufputc: appends a single uint8_t to a buffer */
void
bufputc(struct buf *buf, int c)
{
	assert(buf && buf->unit);

	if (buf->size + 1 > buf->asize && bufgrow(buf, buf->size + 1) < 0)
		return;

	buf->data[buf->size] = c;
	if (buf->is_srcmap_enabled && buf->srcmap)
		buf->srcmap[buf->size] = -1;
	buf->size += 1;
}

/* bufrelease: decrease the reference count and free the buffer if needed */
void
bufrelease(struct buf *buf)
{
	if (!buf)
		return;

	free(buf->data);
	free(buf->srcmap);
	free(buf);
}

void bufdebugsm(struct buf *buf)
{
	for (int i = 0; i < buf->size; i++) {
		if (buf->data[i] == '\n')
			printf("\\n ");
		else
			printf(" %c ", buf->data[i]);
	}
	printf("\n");
	for (int i = 0; i < buf->size; i++) {
		printf("%2d ", (int) buf->srcmap[i]);
	}
	printf("\n");
}

void buf_append_dom_node(struct buf *buf, struct dom_node *node)
{
	if (buf->dom == 0) {
		buf->dom = node;
	} else {
		dom_last_node(buf->dom)->next = node;
	}
}

void bufdebugdom(const struct buf *buf)
{
	dom_print(buf->dom, buf, 0, 0);
}

void bufreleasedom(struct buf *buf)
{
	if (!buf)
		return;
	dom_release(buf->dom);
}
