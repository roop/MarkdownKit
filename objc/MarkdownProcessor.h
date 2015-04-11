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

- (void) willReplaceTextInRange:(NSRange)range ofTextStorage:(NSTextStorage *)textStorage;

- (void) processMarkdownInTextStorage:(NSTextStorage *) textStorage
             syntaxHighlightCallbacks: (BOOL)shouldSyntaxHighlight
                        updatePreview: (BOOL)shouldUpdatePreview;
- (void) processMarkdownInTextStorage: (NSTextStorage *) textStorage
                          editedRange: (NSRange)editedRange
             syntaxHighlightCallbacks: (BOOL)shouldSyntaxHighlight
                        updatePreview: (BOOL)shouldUpdatePreview
           alignPreviewToTextPosition: (NSInteger)position;

- (NSString*)currentHtmlWithEscapedNewlines;

- (MarkdownLinkRefs *)linkRefs;

+ (NSString*)htmlForMarkdownInTextStorage:(NSTextStorage *) textStorage;

+ (void)describeTextStorage:(NSTextStorage *) textStorage;
+ (void)enumerateMarkdownAttributeInTextStorage:(NSTextStorage *)textStorage
    inRange:(NSRange)range options:(NSAttributedStringEnumerationOptions)opts
    usingBlock:(void (^)(NSRange range, BOOL isAttributeFound, MarkdownTextContent textType, MarkdownMarkup markupType, BOOL *stop))block;
+ (void)markdownAttributeAtIndex:(NSUInteger)index ofTextStorage:(NSTextStorage *)textStorage
    isAttributeFound:(BOOL *)found textType:(MarkdownTextContent *)textType markupType:(MarkdownMarkup *) markupType;

@end


@protocol LivePreviewDelegate <NSObject>

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;
- (void)scrollVerticallyBy:(CGFloat)yDiff;

- (CGFloat)topOfCaretAtEditorCursorPosition:(NSInteger)cursorPosition;
- (CGFloat)editorTextAreaHeight;
- (CGFloat)editorLineHeight;

@end