//
//  SyntaxHighlighting.m
//
//  Created by Roopesh Chander on 23/08/14.
//  Copyright (c) 2014 Roopesh Chander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "shl.h"
#include "MarkdownProcessor.h"
#include "SyntaxHighlightArbiter.h"

static void shl_apply_formatting_with_srcmap(void *shl, srcmap_t* srcmap, size_t length, uint16_t fmt, bool isTextFormatting)
{
    if (shl == 0 || srcmap == 0 || length == 0)
        return;
    assert((int)length >= 0);
    struct SyntaxHighlightData shlData;
    if (isTextFormatting) {
        shlData.markupFormatting = 0;
        shlData.textFormatting = fmt;
    } else {
        shlData.markupFormatting = fmt;
        shlData.textFormatting = 0;
    }
    SyntaxHighlightArbiter *shlArbiter = (__bridge SyntaxHighlightArbiter *) shl;
    size_t pos = *srcmap;
    int i = 1, n = 0;
    for (i = 1; i < length; i++) {
        if (srcmap[i] != (pos + i - n)) {
            if (srcmap[i - 1] >= 0) {
                // This range can be mapped to the source
                [shlArbiter ensureTextRange:NSMakeRange(pos, i - n) isSyntaxHighlightedWithData:shlData];
            }
            pos = srcmap[i];
            n = i;
        }
    }
    if (srcmap[length - 1] >= 0) {
        // This range can be mapped to the source
        [shlArbiter ensureTextRange:NSMakeRange(pos, i - n) isSyntaxHighlightedWithData:shlData];
    }
}

void shl_apply_syntax_formatting_with_srcmap(void *shl, srcmap_t* srcmap, size_t length, shl_syntax_formatting_t kind)
{
    assert(sizeof(kind) == sizeof(uint16_t));
    shl_apply_formatting_with_srcmap(shl, srcmap, length, kind, /* isTextFormatting */ false);
}

void shl_apply_text_formatting_with_srcmap(void *shl, srcmap_t* srcmap, size_t length, shl_text_formatting_t kind)
{
    assert(sizeof(kind) == sizeof(uint16_t));
    shl_apply_formatting_with_srcmap(shl, srcmap, length, kind, /* isTextFormatting */ true);
}

void shl_apply_syntax_formatting_with_range(void *shl, size_t pos, size_t length, shl_syntax_formatting_t kind)
{
    if (shl == 0 || length == 0)
        return;
    struct SyntaxHighlightData shlData;
    shlData.markupFormatting = kind;
    shlData.textFormatting = 0;
    SyntaxHighlightArbiter *shlArbiter = (__bridge SyntaxHighlightArbiter *) shl;
    [shlArbiter ensureTextRange:NSMakeRange(pos, length) isSyntaxHighlightedWithData:shlData];
}