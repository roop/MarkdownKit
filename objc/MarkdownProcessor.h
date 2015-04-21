//
//  MarkdownProcessor.h
//  StudyTextKit
//
//  Created by Roopesh Chander on 20/08/14.
//  Copyright (c) 2014 Roopesh Chander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "shl.h"
#import "SyntaxHighlighter.h"
#import "MarkdownLinkRefs.h"

@protocol LivePreviewDelegate;
@protocol SyntaxHighlightDelegate;

@interface MarkdownProcessor : NSObject

@property (nonatomic, strong) SyntaxHighlighter* syntaxHighlighter;
@property (nonatomic, weak) id<LivePreviewDelegate> livePreviewDelegate;

- (void) willReplaceTextInRange:(NSRange)range ofAttributedString:(NSAttributedString *)attrString;

- (void) processMarkdownInTextStorage:(NSTextStorage *)textStorage
             syntaxHighlightCallbacks: (BOOL)shouldSyntaxHighlight
                        updatePreview: (BOOL)shouldUpdatePreview;
- (void) processMarkdownInTextStorage: (NSTextStorage *)textStorage
                          editedRange: (NSRange)editedRange
             syntaxHighlightCallbacks: (BOOL)shouldSyntaxHighlight
                        updatePreview: (BOOL)shouldUpdatePreview
           alignPreviewToTextPosition: (NSInteger)position;

- (NSString*)currentHtmlWithEscapedNewlines;

- (MarkdownLinkRefs *)linkRefs;
- (NSRange)rangeOfRefInDefinitionOfLinkRefName:(NSString *)refName;

+ (NSString*)htmlForMarkdown:(NSString *)markdownString;

+ (void)describeMarkdownAttributedString:(NSAttributedString *)attrString;
+ (void)enumerateMarkdownAttributeInAttributedString:(NSAttributedString *)attrString
    inRange:(NSRange)range options:(NSAttributedStringEnumerationOptions)opts
    usingBlock:(void (^)(NSRange range, BOOL isAttributeFound, MarkdownTextContent textType, MarkdownMarkup markupType, BOOL *stop))block;
+ (void)markdownAttributeAtIndex:(NSUInteger)index ofAttributedString:(NSAttributedString *)attrString
    isAttributeFound:(BOOL *)found textType:(MarkdownTextContent *)textType markupType:(MarkdownMarkup *) markupType;

@end


@protocol LivePreviewDelegate <NSObject>

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;
- (void)scrollVerticallyBy:(CGFloat)yDiff;

- (CGFloat)topOfCaretAtEditorCursorPosition:(NSInteger)cursorPosition;
- (CGFloat)editorTextAreaHeight;
- (CGFloat)editorLineHeight;

@end