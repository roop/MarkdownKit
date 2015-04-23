//
//  SyntaxHighlighting.h
//
//  Created by Roopesh Chander on 23/08/14.
//  Copyright (c) 2014 Roopesh Chander. All rights reserved.
//

#ifndef SyntaxHighlighting_h
#define SyntaxHighlighting_h

#include "buffer.h"

#ifndef __OBJC__

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
    SHL_LIST_ITEM_CONTENT = (1 << 12),
    SHL_BLOCKQUOTE_CONTENT = (1 << 13),

    // Can go upto (1 << 13) = 0x2000

    // Ummergeable text formatting.

    SHL_CODE_BLOCK_CONTENT = (1 << 14),
    SHL_CODE_SPAN_CONTENT = (2 << 14)

    // Can go upto (3 << 14) = 0xC000
};

#else

typedef NS_OPTIONS(uint16_t, MarkdownTextContent) {
    MarkdownTextContentRegular = 0,

    MarkdownTextContentEmphasized = (1 << 0),
    MarkdownTextContentStrong = (1 << 1),
    MarkdownTextContentUnderlined = (1 << 2),
    MarkdownTextContentStrikethrough = (1 << 3),
    MarkdownTextContentHighlighted = (1 << 4),
    MarkdownTextContentLinked = (1 << 5),
    MarkdownTextContentSuperscripted = (1 << 6),

    MarkdownTextContentHeader = (1 << 10),
    MarkdownTextContentTableHeader = (1 << 11),
    MarkdownTextContentListed = (1 << 12),
    MarkdownTextContentBlockquoted = (1 << 13),

    MarkdownTextContentCodeBlock = (1 << 14),
    MarkdownTextContentCodeSpan = (2 << 14)
};

typedef MarkdownTextContent shl_text_formatting_t;

#endif

#ifndef __OBJC__

typedef uint16_t shl_syntax_formatting_t;
enum {
    // Syntax formatting cannot involve font changes.

    SHL_NOT_MARKUP = 0,
    SHL_ATX_HEADER_HASH = 1,
    SHL_SETEXT_HEADER_UNDERLINE,
    SHL_HORIZONTAL_RULE,
    SHL_BLOCKQUOTE_LINE_PREFIX,
    SHL_UNORDERED_LIST_ITEM_PREFIX,
    SHL_ORDERED_LIST_ITEM_PREFIX,
    SHL_CODE_FENCE,
    SHL_TABLE_BORDER,

    SHL_EMPHASIS_OPEN,
    SHL_EMPHASIS_CLOSE,
    SHL_CODE_SPAN_OPEN,
    SHL_CODE_SPAN_CLOSE,

    SHL_LINKED_TEXT_ENCLOSURE,
    SHL_IMG_ALT_TEXT,
    SHL_IMG_ALT_ENCLOSURE,

    SHL_LINK_OR_IMG_INLINE_DATA_ENCLOSURE,
    SHL_LINK_OR_IMG_INLINE_URL,
    SHL_LINK_OR_IMG_INLINE_URL_ENCLOSURE,
    SHL_LINK_OR_IMG_INLINE_TITLE,
    SHL_LINK_OR_IMG_INLINE_TITLE_QUOTES,

    SHL_LINK_OR_IMG_REF,
    SHL_LINK_OR_IMG_REF_ENCLOSURE,

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

#else

typedef NS_ENUM(uint16_t, MarkdownMarkup) {
    MarkdownMarkupNone = 0,
    MarkdownMarkupAtxHeaderHash = 1,
    MarkdownMarkupSetextHeaderUnderline,
    MarkdownMarkupHorizontalRule,
    MarkdownMarkupBlockquoteLinePrefix,
    MarkdownMarkupUnorderedListItemPrefix,
    MarkdownMarkupOrderedListItemPrefix,
    MarkdownMarkupCodeFence,
    MarkdownMarkupTableBorder,

    MarkdownMarkupEmphasisOpen,
    MarkdownMarkupEmphasisClose,
    MarkdownMarkupCodeSpanOpen,
    MarkdownMarkupCodeSpanClose,

    MarkdownMarkupLinkedTextEnclosure,
    MarkdownMarkupImageAltText,
    MarkdownMarkupImageAltEnclosure,

    MarkdownMarkupLinkOrImageInlineDataEnclosure,
    MarkdownMarkupLinkOrImageInlineURL,
    MarkdownMarkupLinkOrImageInlineURLEnclosure,
    MarkdownMarkupLinkOrImageInlineTitle,
    MarkdownMarkupLinkOrImageInlineTitleQuotes,

    MarkdownMarkupLinkOrImageRef,
    MarkdownMarkupLinkOrImageRefEnclosure,

    MarkdownMarkupAutolinkAngleBrackets,
    MarkdownMarkupAutolinkedURL,

    MarkdownMarkupSuperscriptSyntax,

    MarkdownMarkupRefDefinitionRef,
    MarkdownMarkupRefDefinitionRefEnclosure,
    MarkdownMarkupRefDefinitionURL,
    MarkdownMarkupRefDefinitionURLEnclosure,
    MarkdownMarkupRefDefinitionTitle,
    MarkdownMarkupRefDefinitionTitleQuotes,

    MarkdownMarkupFootnoteRef,
    MarkdownMarkupFootnoteRefEnclosure,
    MarkdownMarkupFootnoteDefinitionRef,
    MarkdownMarkupFootnoteDefinitionRefEnclosure,
    MarkdownMarkupFootnoteDefinitionText,

    MarkdownMarkupRawHTMLTag,
    MarkdownMarkupRawHTMLBlockTextContent,
    MarkdownMarkupRawHTMLComment
};

typedef MarkdownMarkup shl_syntax_formatting_t;

#endif

struct SyntaxHighlightData {
    shl_syntax_formatting_t markupFormatting; // If markupFormatting is 0, this is text content, not markup
    shl_text_formatting_t textFormatting; // If both are 0, then this is unformatted text content
};

void shl_apply_text_formatting_with_srcmap(void *shl_data, srcmap_t* srcmap, size_t length, shl_text_formatting_t kind);

void shl_apply_syntax_formatting_with_srcmap(void *shl_data, srcmap_t* srcmap, size_t length, shl_syntax_formatting_t kind);
void shl_apply_syntax_formatting_with_range(void *shl_data, size_t position, size_t length, shl_syntax_formatting_t kind);

#endif
