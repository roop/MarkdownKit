//
//  SyntaxHighlightArbiter.m
//  StudyTextKit
//
//  Created by Roopesh Chander on 26/11/14.
//  Copyright (c) 2014 Roopesh Chander. All rights reserved.
//

#import "SyntaxHighlightArbiter.h"

@implementation SyntaxHighlightArbiter

- (instancetype) init {
    self = [super init];
    if (self) {
        _shouldAskSyntaxHighlighterEvenWhenUnchanged = NO;
    }
    return self;
}

- (void) ensureTextRange:(NSRange)range isSyntaxHighlightedWithData:(struct SyntaxHighlightData) shlData
{
    NSString *shlAttributeName = @"__MDSyntaxHighlight__";
    [self.attributedText
     enumerateAttribute:shlAttributeName inRange:range
     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id v, NSRange range, BOOL *stop) {
         BOOL shlDataChanged = true;
         if (v) {
             struct SyntaxHighlightData shlDataExisting;
             NSValue *value = v;
             [value getValue:&shlDataExisting];
             shlDataChanged = ((shlDataExisting.markupFormatting != shlData.markupFormatting) ||
                                (shlDataExisting.textFormatting != shlData.textFormatting));
         }
         if (_shouldAskSyntaxHighlighterEvenWhenUnchanged || shlDataChanged) {
             // Apply syntax highlighting
             [self.syntaxHighlighter applySyntaxHighlight:shlData inText:self.attributedText range:range];
         }
         if (shlDataChanged) {
             // Update the shlData in the attributed string
             NSValue *shlDataValue = [NSValue valueWithBytes:&shlData objCType:@encode(struct SyntaxHighlightData)];
             [self.attributedText addAttribute:shlAttributeName value:shlDataValue range:range];
         }
     }];
}

@end
