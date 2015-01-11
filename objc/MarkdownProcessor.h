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

@protocol LivePreviewDelegate;
@protocol SyntaxHighlightDelegate;

@interface MarkdownProcessor : NSObject

@property (nonatomic, strong) SyntaxHighlighter* syntaxHighlighter;
@property (nonatomic, weak) id<LivePreviewDelegate> livePreviewDelegate;

- (void) processMarkdownInTextStorage:(NSTextStorage *) textStorage;
- (void) processMarkdownInTextStorage:(NSTextStorage *) textStorage withCursorPosition: (NSInteger) position withSyncScrolling: (BOOL)shouldScroll;

- (NSString*)currentHtmlWithEscapedNewlines;

@end


@protocol LivePreviewDelegate <NSObject>

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;
- (void)scrollVerticallyBy:(CGFloat)yDiff;

- (CGFloat)topOfCaretAtEditorCursorPosition:(NSInteger)cursorPosition;
- (CGFloat)editorTextAreaHeight;
- (CGFloat)editorLineHeight;

@end