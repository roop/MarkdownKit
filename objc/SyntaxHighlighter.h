//
//  SyntaxHighlighter.h
//  StudyTextKit
//
//  Created by Roopesh Chander on 23/08/14.
//  Copyright (c) 2014 Roopesh Chander. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MarkdownProcessor.h"

@interface SyntaxHighlighter : NSObject<SyntaxHighlightDelegate>

@property (nonatomic, weak) NSTextStorage *textStorage;

@end
