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

void shl_apply_syntax_formatting_with_srcmap(void *shl, srcmap_t* srcmap, size_t length, shl_syntax_formatting_t kind)
{
    if (shl == 0 || srcmap == 0 || length == 0)
        return;
    assert((int)length >= 0);
    NSObject<SyntaxHighlightDelegate> *shlDelegate = (__bridge NSObject<SyntaxHighlightDelegate> *) shl;
    size_t pos = *srcmap;
    int i = 1, n = 0;
    for (i = 1; i < length; i++) {
        if (srcmap[i] != (pos + i - n)) {
            if (srcmap[i - 1] >= 0) {
                // This range can be mapped to the source
                [shlDelegate setSyntaxFormatting:kind InRange:NSMakeRange(pos, i - n)];
            }
            pos = srcmap[i];
            n = i;
        }
    }
    if (srcmap[length - 1] >= 0) {
        // This range can be mapped to the source
        [shlDelegate setSyntaxFormatting:kind InRange:NSMakeRange(pos, i - n)];
    }
}

void shl_apply_text_formatting_with_srcmap(void *shl, srcmap_t* srcmap, size_t length, shl_text_formatting_t kind)
{
    if (shl == 0 || srcmap == 0 || length == 0)
        return;
    assert((int)length >= 0);
    NSObject<SyntaxHighlightDelegate> *shlDelegate = (__bridge NSObject<SyntaxHighlightDelegate> *) shl;
    size_t pos = *srcmap;
    int i = 1, n = 0;
    for (i = 1; i < length; i++) {
        if (srcmap[i] != (pos + i - n)) {
            if (srcmap[i - 1] >= 0) {
                // This range can be mapped to the source
                [shlDelegate setTextFormatting:kind InRange:NSMakeRange(pos, i - n)];
            }
            pos = srcmap[i];
            n = i;
        }
    }
    if (srcmap[length - 1] >= 0) {
        // This range can be mapped to the source
        [shlDelegate setTextFormatting:kind InRange:NSMakeRange(pos, i - n)];
    }
}

void shl_apply_syntax_formatting_with_range(void *shl, size_t pos, size_t length, shl_syntax_formatting_t kind)
{
    if (shl == 0 || length == 0)
        return;
    NSObject<SyntaxHighlightDelegate> *shlDelegate = (__bridge NSObject<SyntaxHighlightDelegate> *) shl;
    [shlDelegate setSyntaxFormatting:kind InRange:NSMakeRange(pos, length)];
}
