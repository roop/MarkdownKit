//
//  MarkdownLinkRefs.m
//  Bisect
//
//  Created by Roopesh Chander on 10/04/15.
//  Copyright (c) 2015 Roopesh Chander. All rights reserved.
//

#import "MarkdownLinkRefs.h"
#import "markdown_p.h"

@interface MarkdownLinkRefs () {
    NSArray *_refNames;
    NSDictionary *_refNameURLDictionary;
    NSArray *_refNamesDefinedButNotUsed;
}

@end

@implementation MarkdownLinkRefs

- (instancetype)initWithText:(NSString *)text markdownData:(struct sd_markdown *)markdown_data
{
    self = [super init];
    if (self) {
        NSMutableArray *refNames = [[NSMutableArray alloc] init];
        NSMutableSet *refURLs;
        NSMutableDictionary *refURLForName = [[NSMutableDictionary alloc] init];
        NSMutableArray *refNamesDefinedButNotUsed = [[NSMutableArray alloc] init];
        for (int i = 0; i < REF_TABLE_SIZE; i++) {
            struct link_ref *ref = markdown_data->refs[i];
            while (ref != 0) {
                NSRange rangeInText = NSMakeRange(ref->ref_name_srcmap_pos, ref->ref_name_srcmap_len);
                NSString *refName = [text substringWithRange:rangeInText];
                NSString *linkURLStr = [[NSString alloc] initWithBytes:ref->link->data length:ref->link->size
                                                                    encoding:NSUTF8StringEncoding];
                // Populate refNames
                NSUInteger insertionIndex = [refNames indexOfObject:refName
                                                      inSortedRange:NSMakeRange(0, refNames.count) options:NSBinarySearchingInsertionIndex
                                                    usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                        NSString *str1 = obj1;
                                                        NSString *str2 = obj2;
                                                        return [str1 caseInsensitiveCompare:str2];
                                                    }];
                [refNames insertObject:refName atIndex:insertionIndex];
                [refURLs addObject:linkURLStr];
                [refURLForName setValue:linkURLStr forKey:[refName lowercaseString]];
                if (!ref->is_used) {
                    [refNamesDefinedButNotUsed addObject:refName];
                }
                // Move ahead in the linked list
                ref = ref->next;
            }
        }
        // Set ivars
        _refNames = refNames;
        _refNameURLDictionary = refURLForName;
        _refNamesDefinedButNotUsed = refNamesDefinedButNotUsed;
    }
    return self;
}

- (NSArray *)refNames
{
    return _refNames;
}

- (NSDictionary*)refNameURLDictionary
{
    return _refNameURLDictionary;
}

- (NSArray *)refNamesDefinedButNotUsed
{
    return _refNamesDefinedButNotUsed;
}

+ (NSRange)rangeOfRefInDefinitionOfLinkRefName:(NSString *)refName usingText:(NSString *)text
                               andMarkdownData:(struct sd_markdown *)markdown_data
{
    for (int i = 0; i < REF_TABLE_SIZE; i++) {
        struct link_ref *ref = markdown_data->refs[i];
        while (ref != 0) {
            NSRange rangeInText = NSMakeRange(ref->ref_name_srcmap_pos, ref->ref_name_srcmap_len);
            NSString *refNameOfRef = [text substringWithRange:rangeInText];
            if ([refNameOfRef caseInsensitiveCompare:refName] == NSOrderedSame) {
                return rangeInText;
            }
            ref = ref->next;
        }
    }
    return NSMakeRange(NSNotFound, 0);
}

@end
