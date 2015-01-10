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

    // Add foreground color, if applicable
    UIColor *fgColor = [self foregroundColorForSyntaxFormatting:fmt];
    if (fgColor) {
        [str addAttribute:NSForegroundColorAttributeName value:fgColor range:range];
    } else {
        [str removeAttribute:NSForegroundColorAttributeName range:range];
    }
}

static void applyTextFormattingUnderlineStrikethrough(NSDictionary *attrs, NSString *attrName,
                                                      shl_text_formatting_t fmt_match,
                                                      NSMutableAttributedString *textStorage, shl_text_formatting_t fmt, NSRange range);

- (void) applyTextFormatting:(shl_text_formatting_t)fmt inText:(NSMutableAttributedString *)str range:(NSRange)range
{
    [str
     enumerateAttributesInRange:range
     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
     usingBlock:^(NSDictionary *attributes, NSRange range, BOOL *stop) {

         // Font
         // Not setting font attributes because it's hard to update them all when we need to change the font size
         // [self applyFontAttributesUsingTextFormatting:fmt inText:str range:range existingAttributes:attributes];

         // Underline
         applyTextFormattingUnderlineStrikethrough(attributes,
                                                   NSUnderlineStyleAttributeName, MarkdownTextContentUnderlined,
                                                   str, fmt, range);
         // Strikethrough
         applyTextFormattingUnderlineStrikethrough(attributes,
                                                   NSStrikethroughStyleAttributeName, MarkdownTextContentStrikethrough,
                                                   str, fmt, range);

         // Add foreground color, if applicable
         UIColor *fgColor = [self foregroundColorForTextFormatting:fmt];
         if (fgColor) {
             [str addAttribute:NSForegroundColorAttributeName value:fgColor range:range];
         } else {
             [str removeAttribute:NSForegroundColorAttributeName range:range];
         }
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

- (UIColor *) foregroundColorForSyntaxFormatting:(MarkdownMarkup) fmt
{
    switch (fmt) {

        case MarkdownMarkupAutolinkedURL:
            return [UIColor blueColor];

        case MarkdownMarkupLinkOrImageURL:
        case MarkdownMarkupRefDefinitionURL:
            return [self dimmedBlueColor];

        case MarkdownMarkupImageAltText:
            return [UIColor purpleColor];

        case MarkdownMarkupLinkOrImageTitle:
        case MarkdownMarkupRefDefinitionTitle:
            return [UIColor grayColor];

        case MarkdownMarkupLinkOrImageRef:
        case MarkdownMarkupFootnoteRef:
            return [UIColor grayColor];

        case MarkdownMarkupRefDefinitionRef:
        case MarkdownMarkupFootnoteDefinitionRef:
            return [UIColor grayColor];

        case MarkdownMarkupFootnoteDefinitionText:
            return [UIColor grayColor];

        case MarkdownMarkupRawHTMLBlockTextContent:
            return [UIColor blackColor];

        default:
            return [UIColor lightGrayColor];
    }
    return [UIColor lightGrayColor];
}

- (UIColor *) foregroundColorForTextFormatting:(MarkdownTextContent) fmt
{
    if ((fmt & MarkdownTextContentLinked) == MarkdownTextContentLinked) {
        return [UIColor blueColor];
    }
    return nil;
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
    if (((fmt & MarkdownTextContentStrong) == MarkdownTextContentStrong) ||
        ((fmt & MarkdownTextContentHeader) == MarkdownTextContentHeader) ||
        ((fmt & MarkdownTextContentTableHeader) == MarkdownTextContentTableHeader)) {
        // bold
        if ((fmt & MarkdownTextContentEmphasized) == MarkdownTextContentEmphasized) {
            // And italic
            return self.boldItalicFont;
        } else {
            // Just bold
            return self.boldFont;
        }
    } else {
        // Not bold
        if ((fmt & MarkdownTextContentEmphasized) == MarkdownTextContentEmphasized) {
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
