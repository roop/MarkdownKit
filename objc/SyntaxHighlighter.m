//
//  SyntaxHighlighter.m
//  StudyTextKit
//
//  Created by Roopesh Chander on 23/08/14.
//  Copyright (c) 2014 Roopesh Chander. All rights reserved.
//

#import "SyntaxHighlighter.h"

@interface SyntaxHighlighter ()
- (UIColor *) dimmedBlueColor;
- (UIColor *) veryLightGrayColor;
- (UIColor *) foregroundColorForSyntaxFormatting:(shl_syntax_formatting_t) fmt;
@end

@implementation SyntaxHighlighter {
    UIColor *_dimmedBlueColor;
    UIColor *_veryLightGrayColor;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dimmedBlueColor = nil;
        _veryLightGrayColor = nil;
    }
    return self;
}

#pragma mark - SyntaxHighlightDelegate

static UIFontDescriptorSymbolicTraits typefaceTraitsForTextFormatting(shl_text_formatting_t fmt);
static UIFontDescriptorSymbolicTraits typefaceTraitsUsedForTextFormatting();

- (void) setSyntaxFormatting:(shl_syntax_formatting_t)fmt InRange: (NSRange)range
{
    __block UIColor *requiredFgColor = nil;
    [_textStorage
     enumerateAttributesInRange:range
     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
     usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
         UIFont *font = attrs[NSFontAttributeName];
         if (font) {
             UIFontDescriptor *fontDescriptor = [font fontDescriptor];
             UIFontDescriptorSymbolicTraits traits = [fontDescriptor symbolicTraits];
             UIFontDescriptorSymbolicTraits typefaceTraits = (traits & typefaceTraitsUsedForTextFormatting());
             if (typefaceTraits) {
                 UIFontDescriptorSymbolicTraits noTypefaceTraits = (traits ^ typefaceTraits);
                 UIFont *overrideFont = [UIFont fontWithDescriptor:[fontDescriptor fontDescriptorWithSymbolicTraits:noTypefaceTraits] size:[font pointSize]];
                 [_textStorage addAttribute:NSFontAttributeName value:overrideFont range:range];
             }
         }
         UIColor *bgColor = attrs[NSBackgroundColorAttributeName];
         if (bgColor) {
             [_textStorage removeAttribute:NSBackgroundColorAttributeName range:range];
         }
         UIColor *fgColor = attrs[NSForegroundColorAttributeName];
         if (fgColor) {
             if (requiredFgColor == nil) {
                 requiredFgColor = [self foregroundColorForSyntaxFormatting:fmt];
             }
             if (![fgColor isEqual:requiredFgColor]) {
                 [_textStorage addAttribute:NSForegroundColorAttributeName value:requiredFgColor range:range];
             }
         } else {
             if (requiredFgColor == nil) {
                 requiredFgColor = [self foregroundColorForSyntaxFormatting:fmt];
             }
             [_textStorage addAttribute:NSForegroundColorAttributeName value:requiredFgColor range:range];
         }
     }];
}

static void applyTextFormattingUnderlineStrikethrough(NSDictionary *attrs, NSString *attrName,
                                                      shl_text_formatting_t fmt_match,
                                                      NSTextStorage *textStorage, shl_text_formatting_t fmt, NSRange range);
static void applyTextFormattingColor(NSDictionary *attrs, NSString *attrName,
                                     shl_text_formatting_t fmt_match, UIColor *color,
                                     NSTextStorage *textStorage, shl_text_formatting_t fmt, NSRange range);

- (void) setTextFormatting:(shl_text_formatting_t)fmt InRange: (NSRange)range
{
    [_textStorage
     enumerateAttributesInRange:range
     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
     usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
         UIFont *font = attrs[NSFontAttributeName];
         if (font) {
             // Make sure font typeface traits match what we want (like bold, italics, etc.)
             UIFontDescriptor *fontDescriptor = [font fontDescriptor];
             UIFontDescriptorSymbolicTraits traits = [fontDescriptor symbolicTraits];
             UIFontDescriptorSymbolicTraits typefaceTraits = (traits & typefaceTraitsUsedForTextFormatting());
             UIFontDescriptorSymbolicTraits reqdTypefaceTraits = typefaceTraitsForTextFormatting(fmt);
             if (typefaceTraits != reqdTypefaceTraits) {
                 UIFont *overrideFont = [UIFont fontWithDescriptor:[fontDescriptor fontDescriptorWithSymbolicTraits:reqdTypefaceTraits] size:[font pointSize]];
                 [_textStorage addAttribute:NSFontAttributeName value:overrideFont range:range];
             }
         }
         applyTextFormattingUnderlineStrikethrough(attrs, NSUnderlineStyleAttributeName, SHL_UNDERLINE_CONTENT,
                                                   _textStorage, fmt, range);
         applyTextFormattingUnderlineStrikethrough(attrs, NSStrikethroughStyleAttributeName, SHL_STRIKETHROUGH_CONTENT,
                                                   _textStorage, fmt, range);
         applyTextFormattingColor(attrs, NSForegroundColorAttributeName, SHL_LINKED_CONTENT, [UIColor blueColor],
                                  _textStorage, fmt, range);

         applyTextFormattingColor(attrs, NSBackgroundColorAttributeName, SHL_CODE_SPAN_CONTENT, [self veryLightGrayColor],
                                  _textStorage, fmt, range);
     }];
}

#pragma mark - char attributes for syntax constructs

- (UIColor *)dimmedBlueColor
{
    if (!_dimmedBlueColor) {
        _dimmedBlueColor = [[UIColor alloc] initWithRed:0.2 green:0.2 blue:0.9 alpha:0.8];
    }
    return _dimmedBlueColor;
}

- (UIColor *)veryLightGrayColor
{
    if (!_veryLightGrayColor) {
        _veryLightGrayColor = [[UIColor alloc] initWithRed:0.8 green:0.8 blue:0.8 alpha:0.5];
    }
    return _veryLightGrayColor;
}

- (UIColor *) foregroundColorForSyntaxFormatting:(shl_syntax_formatting_t) fmt
{
    switch (fmt) {

        case SHL_AUTOLINKED_URL:
            return [UIColor blueColor];

        case SHL_LINK_OR_IMG_URL:
        case SHL_REF_DEFINITION_URL:
            return [self dimmedBlueColor];

        case SHL_IMG_ALT_TEXT:
            return [UIColor purpleColor];

        case SHL_LINK_OR_IMG_TITLE:
        case SHL_REF_DEFINITION_TITLE:
            return [UIColor grayColor];

        case SHL_LINK_OR_IMG_REF:
        case SHL_FOOTNOTE_REF:
            return [UIColor grayColor];

        case SHL_REF_DEFINITION_REF:
        case SHL_FOOTNOTE_DEFINITION_REF:
            return [UIColor grayColor];

        case SHL_FOOTNOTE_DEFINITION_TEXT:
            return [UIColor grayColor];

        case SHL_RAW_HTML_BLOCK_TEXT_CONTENT:
            return [UIColor blackColor];

        default:
            return [UIColor lightGrayColor];
    }
    return [UIColor lightGrayColor];
}

@end

#pragma mark - static helper functions

static void applyTextFormattingUnderlineStrikethrough(NSDictionary *attrs, NSString *attrName,
                                                      shl_text_formatting_t fmt_match,
                                                      NSTextStorage *textStorage, shl_text_formatting_t fmt, NSRange range)
{
    BOOL isPresent = ([attrs[attrName] integerValue] != NSUnderlineStyleNone);
    BOOL shouldBePresent = ((fmt & fmt_match) == fmt_match);
    if (isPresent == shouldBePresent) {
        return;
    }
    if (shouldBePresent) {
        [textStorage addAttribute:attrName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:range];
    } else {
        [textStorage removeAttribute:attrName range:range];
    }
}

static void applyTextFormattingColor(NSDictionary *attrs, NSString *attrName,
                                     shl_text_formatting_t fmt_match, UIColor *color,
                                     NSTextStorage *textStorage, shl_text_formatting_t fmt, NSRange range)
{
    UIColor *existingColor = attrs[attrName];
    UIColor *requiredColor = ((fmt & fmt_match) == fmt_match) ? color : nil;
    if ((existingColor == nil && requiredColor == nil) ||
        ([existingColor isEqual:requiredColor])) {
        return;
    }
    if (requiredColor) {
        [textStorage addAttribute:attrName value:requiredColor range:range];
    } else {
        [textStorage removeAttribute:attrName range:range];
    }
}

static UIFontDescriptorSymbolicTraits typefaceTraitsForTextFormatting(shl_text_formatting_t fmt)
{
    UIFontDescriptorSymbolicTraits typefaceTraits = 0;
    if (fmt & SHL_EM_CONTENT) {
        typefaceTraits |= UIFontDescriptorTraitItalic;
    }
    if (fmt & SHL_STRONG_CONTENT) {
        typefaceTraits |= UIFontDescriptorTraitBold;
    }
    if ((fmt & SHL_CODE_BLOCK_CONTENT) || (fmt & SHL_CODE_SPAN_CONTENT)) {
        // Do nothing
    }
    if ((fmt & SHL_HEADER_CONTENT) || (fmt & SHL_TABLE_HEADER_CELL_CONTENT)) {
        typefaceTraits |= UIFontDescriptorTraitBold;
    }
    return typefaceTraits;
}

static UIFontDescriptorSymbolicTraits typefaceTraitsUsedForTextFormatting()
{
    return (UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold);
}
