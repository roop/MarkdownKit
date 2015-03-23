//
//  SyntaxHighlightArbiter.h
//  StudyTextKit
//
//  Created by Roopesh Chander on 26/11/14.
//  Copyright (c) 2014 Roopesh Chander. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SyntaxHighlighter.h"
#import "shl.h"

#define SHL_STRING_ATTRIBUTE_NAME @"__MDSyntaxHighlight__"

@interface SyntaxHighlightArbiter : NSObject

@property (nonatomic, weak) NSMutableAttributedString *attributedText;
@property (nonatomic, strong) SyntaxHighlighter *syntaxHighlighter;
@property (nonatomic) BOOL shouldAskSyntaxHighlighterEvenWhenUnchanged;

- (void) ensureTextRange:(NSRange)range isSyntaxHighlightedWithData:(struct SyntaxHighlightData) shlData;

@end
