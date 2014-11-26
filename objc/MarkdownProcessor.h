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


@protocol LivePreviewDelegate;
@protocol SyntaxHighlightDelegate;


@interface MarkdownProcessor : NSObject<NSTextStorageDelegate>

@property (nonatomic, weak) id<SyntaxHighlightDelegate> syntaxHighlightDelegate;
@property (nonatomic, weak) id<LivePreviewDelegate> livePreviewDelegate;
@property (nonatomic, weak) UITextView *textEditor;

@end


@protocol SyntaxHighlightDelegate <NSObject>

- (void) setSyntaxFormatting:(shl_syntax_formatting_t)kind InRange: (NSRange)range;
- (void) setTextFormatting:(shl_text_formatting_t)kind InRange: (NSRange)range;

@end


@protocol LivePreviewDelegate <NSObject>

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;
- (void)scrollVerticallyBy:(CGFloat)yDiff;

@end