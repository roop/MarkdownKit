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

@interface MarkdownProcessor : NSObject<NSTextStorageDelegate>

@property (nonatomic, strong) SyntaxHighlighter* syntaxHighlighter;
@property (nonatomic, weak) NSTextStorage* textStorage;
@property (nonatomic, weak) id<LivePreviewDelegate> livePreviewDelegate;
@property (nonatomic, weak) UITextView *textEditor;

@end


@protocol LivePreviewDelegate <NSObject>

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;
- (void)scrollVerticallyBy:(CGFloat)yDiff;

@end