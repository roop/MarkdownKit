//
//  MarkdownLinkRefs.h
//  Bisect
//
//  Created by Roopesh Chander on 10/04/15.
//  Copyright (c) 2015 Roopesh Chander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "markdown_p.h"

@interface MarkdownLinkRefs : NSObject

- (instancetype)initWithText:(NSString *)text markdownData:(struct sd_markdown *)markdown_data;

- (NSArray *)refNames; // Sorted
- (NSDictionary*)refNameURLDictionary;
- (NSArray *)refNamesDefinedButNotUsed; // Unordered

+ (NSRange)rangeOfRefInDefinitionOfLinkRefName:(NSString *)refName usingText:(NSString *)text
                               andMarkdownData:(struct sd_markdown *)markdown_data;

@end
