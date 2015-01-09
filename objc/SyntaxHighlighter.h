//
//  SyntaxHighlighter.h
//  StudyTextKit
//
//  Created by Roopesh Chander on 23/08/14.
//  Copyright (c) 2014 Roopesh Chander. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "shl.h"

@interface SyntaxHighlighter : NSObject

@property (nonatomic, strong) UIFont *defaultFont;

// This is the entry-point method
- (void) applySyntaxHighlight:(struct SyntaxHighlightData)shlData inText:(NSMutableAttributedString *)str range:(NSRange)range;

// The following are meant to be overridden in subclasses, as required

// For adopting a color scheme
- (UIColor *) foregroundColorForSyntaxFormatting:(MarkdownMarkup) fmt;
- (UIColor *) foregroundColorForTextFormatting:(MarkdownTextContent) fmt;

// For more control
- (void) applyMarkupFormatting:(shl_syntax_formatting_t)fmt inText:(NSMutableAttributedString *)str range:(NSRange)range;
- (void) applyTextFormatting:(shl_text_formatting_t)fmt inText:(NSMutableAttributedString *)str range:(NSRange)range;
- (void) applyFontAttributesUsingTextFormatting:(shl_text_formatting_t)fmt
                                         inText:(NSMutableAttributedString *)str range:(NSRange)range
                             existingAttributes:(NSDictionary *)attributes;

@end
