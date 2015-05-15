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

    NSString *_lastSearchedRefNamePrefix;
    NSRange _lastRefNamePrefixSearchResult;
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
        _lastSearchedRefNamePrefix = nil;
        _lastRefNamePrefixSearchResult = NSMakeRange(NSNotFound, 0);
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

- (NSRange) refNamesArrayRangeForPrefix: (NSString *)prefix maxLength:(NSUInteger)maxLength {
    NSArray *refNames = _refNames;
    NSRange searchScope = NSMakeRange(0, refNames.count);

    if (_lastSearchedRefNamePrefix != nil) {

        // If prefix exactly matches _lastSearchedRefNamePrefix
        if ([prefix compare:_lastSearchedRefNamePrefix options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            return _lastRefNamePrefixSearchResult;
        }

        // If prefix partially matches _lastSearchedRefNamePrefix
        if ((_lastSearchedRefNamePrefix.length < prefix.length) &&
            ([prefix compare:_lastSearchedRefNamePrefix options:NSCaseInsensitiveSearch
                       range:NSMakeRange(0, _lastSearchedRefNamePrefix.length)] == NSOrderedSame)) {
            // E.g. We had the result for "pod" cached, and we're looking for "poda" now.
            // ("poda"'s range start >= "pod"'s range start)
            if (_lastRefNamePrefixSearchResult.length > 0) {
                searchScope = NSMakeRange(_lastRefNamePrefixSearchResult.location, refNames.count - _lastRefNamePrefixSearchResult.location);
            } else {
                return NSMakeRange(NSNotFound, 0);
            }
        } else if ((prefix.length < _lastSearchedRefNamePrefix.length) &&
                   ([_lastSearchedRefNamePrefix compare:prefix options:NSCaseInsensitiveSearch
                                                  range:NSMakeRange(0, prefix.length)] == NSOrderedSame)) {
            // E.g. We had the result for "poda" cached, and we're looking for "pod" now.
            // ("pod"'s range start <= "poda"'s range start)
            if (_lastRefNamePrefixSearchResult.length > 0) {
                searchScope = NSMakeRange(0, _lastRefNamePrefixSearchResult.location + 1);
            }
        }
    }


    NSUInteger insertionIndex = [refNames indexOfObject:prefix
                                          inSortedRange:searchScope options:NSBinarySearchingInsertionIndex
                                        usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                            NSString *str1 = obj1;
                                            NSString *str2 = obj2;
                                            return [str1 caseInsensitiveCompare:str2];
                                        }];
    NSUInteger length = 0;
    NSRange prefixRange = NSMakeRange(0, prefix.length);
    for (NSUInteger i = insertionIndex; i < refNames.count; i++) {
        BOOL hasPrefix = ([refNames[i] compare:prefix options:NSCaseInsensitiveSearch range:prefixRange] == NSOrderedSame);
        if (hasPrefix) {
            length++;
        } else {
            break;
        }
        if (length >= maxLength) {
            break;
        }
    }
    NSRange result = NSMakeRange(insertionIndex, length);

    _lastSearchedRefNamePrefix = prefix;
    _lastRefNamePrefixSearchResult = result;

    return result;
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
