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

	srcmap_t begin = srcmap[0];
	srcmap_t prev_sm = begin;
	for (int i = 1; i < length; i++) {
		srcmap_t sm = srcmap[i];
		if (begin < 0) {
			if (sm > 0) {
				begin = sm; // Need a valid begin first
			}
		} else {
			if (prev_sm >= 0) {
				if ((sm < 0) || ((sm - prev_sm) > 1)) {
					// A contiguous sequence ended at prev_sm
					assert(begin >= 0);
					if (prev_sm >= begin) {
						NSRange stringRange = NSMakeRange(begin, prev_sm - begin + 1);
						[shlArbiter ensureTextRange:stringRange isSyntaxHighlightedWithData:shlData];
						begin = sm;
					}
				}
			}
		}
		prev_sm = sm;
	}

	if (begin >= 0 && prev_sm >= begin) {
		NSRange stringRange = NSMakeRange(begin, prev_sm - begin + 1);
		[shlArbiter ensureTextRange:stringRange isSyntaxHighlightedWithData:shlData];
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