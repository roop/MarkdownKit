//
//  SyntaxHighlighting.h
//
//  Created by Roopesh Chander on 23/08/14.
//  Copyright (c) 2014 Roopesh Chander. All rights reserved.
//

#ifndef SyntaxHighlighting_h
#define SyntaxHighlighting_h

#include "buffer.h"

typedef uint16_t shl_text_formatting_t;
enum {
    // Text formatting can involve font changes.

    // Mergeable text formatting.
    // Multiple mergeable formattings can apply
    // to the same text range.

    SHL_TEXT_CONTENT = 0,

    SHL_EM_CONTENT = (1 << 0),
    SHL_STRONG_CONTENT = (1 << 1),
    SHL_UNDERLINE_CONTENT = (1 << 2),
    SHL_STRIKETHROUGH_CONTENT = (1 << 3),
    SHL_HIGHLIGHT_CONTENT = (1 << 4),
    SHL_LINKED_CONTENT = (1 << 5),
	SHL_SUPERSCRIPTED_CONTENT = (1 << 6),

	SHL_HEADER_CONTENT = (1 << 10),
	SHL_TABLE_HEADER_CELL_CONTENT = (1 << 11),

	// Can go upto (1 << 13) = 0x2000

    // Ummergeable text formatting.

    SHL_CODE_BLOCK_CONTENT = (1 << 14),
    SHL_CODE_SPAN_CONTENT = (2 << 14)

	// Can go upto (3 << 14) = 0xC000
};

typedef uint16_t shl_syntax_formatting_t;
enum {
    // Syntax formatting cannot involve font changes.

	SHL_ATX_HEADER_HASH = 1,
	SHL_SETEXT_HEADER_UNDERLINE,
	SHL_HORIZONTAL_RULE,
	SHL_BLOCKQUOTE_LINE_PREFIX,
	SHL_LIST_ITEM_PREFIX,
	SHL_CODE_FENCE,
	SHL_TABLE_BORDER,

	SHL_EMPHASIS_CHAR,
	SHL_CODE_SPAN_CHAR,

	SHL_LINK_OR_IMG_SYNTAX,
	SHL_LINK_OR_IMG_REF,
	SHL_LINK_OR_IMG_REF_ENCLOSURE,
	SHL_LINK_OR_IMG_URL,
	SHL_LINK_OR_IMG_TITLE,
	SHL_LINK_OR_IMG_TITLE_QUOTES,
	SHL_IMG_ALT_TEXT,
	SHL_AUTOLINK_ANGLE_BRACKETS,
	SHL_AUTOLINKED_URL,

	SHL_SUPERSCRIPT_SYNTAX,

	SHL_REF_DEFINITION_REF,
	SHL_REF_DEFINITION_REF_ENCLOSURE,
	SHL_REF_DEFINITION_URL,
	SHL_REF_DEFINITION_URL_ENCLOSURE,
	SHL_REF_DEFINITION_TITLE,
	SHL_REF_DEFINITION_TITLE_QUOTES,

	SHL_FOOTNOTE_REF,
	SHL_FOOTNOTE_REF_ENCLOSURE,
	SHL_FOOTNOTE_DEFINITION_REF,
	SHL_FOOTNOTE_DEFINITION_REF_ENCLOSURE,
	SHL_FOOTNOTE_DEFINITION_TEXT,

	SHL_RAW_HTML_TAG,
	SHL_RAW_HTML_BLOCK_TEXT_CONTENT,
	SHL_RAW_HTML_COMMENT,
};

void shl_apply_text_formatting_with_srcmap(void *shl_data, srcmap_t* srcmap, size_t length, shl_text_formatting_t kind);

void shl_apply_syntax_formatting_with_srcmap(void *shl_data, srcmap_t* srcmap, size_t length, shl_syntax_formatting_t kind);
void shl_apply_syntax_formatting_with_range(void *shl_data, size_t position, size_t length, shl_syntax_formatting_t kind);

#endif
