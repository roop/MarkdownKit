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
- (UIFont *) italicFont;
- (UIFont *) boldFont;
- (UIFont *) boldItalicFont;
@end

@implementation SyntaxHighlighter {
    UIColor *_dimmedBlueColor;
    UIColor *_veryLightGrayColor;
    UIFont *_italicFont;
    UIFont *_boldFont;
    UIFont *_boldItalicFont;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dimmedBlueColor = nil;
        _veryLightGrayColor = nil;
        _italicFont = nil;
        _boldFont = nil;
        _boldItalicFont = nil;
    }
    return self;
}

- (void)setDefaultFont:(UIFont *)defaultFont
{
    _defaultFont = defaultFont;
    _italicFont = nil;
    _boldFont = nil;
    _boldItalicFont = nil;
}

#pragma mark - SyntaxHighlightDelegate

- (void) applySyntaxHighlight:(struct SyntaxHighlightData)shlData inText:(NSMutableAttributedString *)str range:(NSRange)range
{
    if (shlData.markupFormatting > 0) {
        // Markup
        [self applyMarkupFormatting:shlData.markupFormatting inText:str range:range];
    } else {
        // Text
        [self applyTextFormatting:shlData.textFormatting inText:str range:range];
    }
}

- (void) applyMarkupFormatting:(shl_syntax_formatting_t)fmt inText:(NSMutableAttributedString *)str range:(NSRange)range
{
    // Apply default font (to remove bold, italics, etc., if present)
    if (self.defaultFont) {
        [str addAttribute:NSFontAttributeName value:self.defaultFont range:range];
    }

    // Remove background color
    [str removeAttribute:NSBackgroundColorAttributeName range:range];

    // Add foreground color, if applicable
    [str addAttribute:NSForegroundColorAttributeName
                value:[self foregroundColorForSyntaxFormatting:fmt]
                range:range];
}

static void applyTextFormattingUnderlineStrikethrough(NSDictionary *attrs, NSString *attrName,
                                                      shl_text_formatting_t fmt_match,
                                                      NSMutableAttributedString *textStorage, shl_text_formatting_t fmt, NSRange range);
static void applyTextFormattingColor(NSDictionary *attrs, NSString *attrName,
                                     shl_text_formatting_t fmt_match, UIColor *color,
                                     NSMutableAttributedString *textStorage, shl_text_formatting_t fmt, NSRange range);

- (void) applyTextFormatting:(shl_text_formatting_t)fmt inText:(NSMutableAttributedString *)str range:(NSRange)range
{
    [str
     enumerateAttributesInRange:range
     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
     usingBlock:^(NSDictionary *attributes, NSRange range, BOOL *stop) {

         // Font
         [self applyFontAttributesUsingTextFormatting:fmt inText:str range:range existingAttributes:attributes];

         // Underline
         applyTextFormattingUnderlineStrikethrough(attributes,
                                                   NSUnderlineStyleAttributeName, SHL_UNDERLINE_CONTENT,
                                                   str, fmt, range);
         // Strikethrough
         applyTextFormattingUnderlineStrikethrough(attributes,
                                                   NSUnderlineStyleAttributeName, SHL_UNDERLINE_CONTENT,
                                                   str, fmt, range);
         // Foreground Color
         applyTextFormattingColor(attributes,
                                  NSForegroundColorAttributeName, SHL_LINKED_CONTENT, [UIColor blueColor],
                                  str, fmt, range);
         // Background Color
         applyTextFormattingColor(attributes,
                                  NSBackgroundColorAttributeName, SHL_CODE_SPAN_CONTENT, [self veryLightGrayColor],
                                  str, fmt, range);
     }];
}

- (void) applyFontAttributesUsingTextFormatting:(shl_text_formatting_t)fmt
                                         inText:(NSMutableAttributedString *)str range:(NSRange)range
                             existingAttributes:(NSDictionary *)attributes {
    UIFont *font = [self fontForTextFormatting:fmt];
    [str addAttribute:NSFontAttributeName value:font range:range];
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

- (UIFont *)italicFont
{
    if (!_italicFont) {
        UIFontDescriptor *fontDescriptor =
        [UIFontDescriptor
         fontDescriptorWithFontAttributes:@{
                                            @"NSFontFamilyAttribute": self.defaultFont.familyName,
                                            @"NSFontFaceAttribute": @"Italic"
                                            }];
        _italicFont = [UIFont fontWithDescriptor:fontDescriptor size:self.defaultFont.pointSize];
    }
    return _italicFont;
}

- (UIFont *)boldFont
{
    if (!_boldFont) {
        UIFontDescriptor *fontDescriptor =
        [UIFontDescriptor
         fontDescriptorWithFontAttributes:@{
                                            @"NSFontFamilyAttribute": self.defaultFont.familyName,
                                            @"NSFontFaceAttribute": @"Bold"
                                            }];
        _boldFont = [UIFont fontWithDescriptor:fontDescriptor size:self.defaultFont.pointSize];
    }
    return _boldFont;
}

- (UIFont *)boldItalicFont
{
    if (!_boldItalicFont) {
        UIFontDescriptor *fontDescriptor =
        [UIFontDescriptor
         fontDescriptorWithFontAttributes:@{
                                            @"NSFontFamilyAttribute": self.defaultFont.familyName,
                                            @"NSFontFaceAttribute": @"Bold Italic"
                                            }];
        _boldItalicFont = [UIFont fontWithDescriptor:fontDescriptor size:self.defaultFont.pointSize];
    }
    return _boldItalicFont;
}

- (UIFont *) fontForTextFormatting:(shl_text_formatting_t) fmt
{
    if (((fmt & SHL_STRONG_CONTENT) == SHL_STRONG_CONTENT) ||
        ((fmt & SHL_HEADER_CONTENT) == SHL_HEADER_CONTENT) ||
        ((fmt & SHL_TABLE_HEADER_CELL_CONTENT) == SHL_TABLE_HEADER_CELL_CONTENT)) {
        // bold
        if ((fmt & SHL_EM_CONTENT) == SHL_EM_CONTENT) {
            // And italic
            return self.boldItalicFont;
        } else {
            // Just bold
            return self.boldFont;
        }
    } else {
        // Not bold
        if ((fmt & SHL_EM_CONTENT) == SHL_EM_CONTENT) {
            // Just italic
            return self.italicFont;
        }
    }
    // Nothing special
    return self.defaultFont;
}

@end

#pragma mark - static helper functions

static void applyTextFormattingUnderlineStrikethrough(NSDictionary *attrs, NSString *attrName,
                                                      shl_text_formatting_t fmt_match,
                                                      NSMutableAttributedString *textStorage, shl_text_formatting_t fmt, NSRange range)
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
                                     NSMutableAttributedString *textStorage, shl_text_formatting_t fmt, NSRange range)
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
