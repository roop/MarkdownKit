//
//  MarkdownProcessor.m
//  StudyTextKit
//
//  Created by Roopesh Chander on 20/08/14.
//  Copyright (c) 2014 Roopesh Chander. All rights reserved.
//

#import "MarkdownProcessor.h"
#import "SyntaxHighlightArbiter.h"
#include "markdown.h"
#include "html.h"
#include "buffer.h"
#include "dom.h"

#define BUFFER_GROW_SIZE 1024

// #define DEBUG_JS_DIFF 1

@interface MarkdownProcessor () {
    SyntaxHighlightArbiter *_syntaxHighlightArbiter;
    BOOL _isLivePreviewUpdatePending;
    NSInteger _effectiveEditorCursorPos;
    struct buf *_prev_ob, *_cur_ob;
}

- (void) updateLivePreview;

@end


@implementation MarkdownProcessor

- (instancetype)init
{
    self = [super init];
    if (self) {
        _syntaxHighlightArbiter = [SyntaxHighlightArbiter new];
        _isLivePreviewUpdatePending = NO;
        _effectiveEditorCursorPos = -1;
        _prev_ob = 0;
        _cur_ob = 0;
    }
    return self;
}

- (void) processMarkdownInTextStorage:(NSTextStorage *) textStorage
             syntaxHighlightCallbacks: (BOOL)shouldSyntaxHighlight
                        updatePreview: (BOOL)shouldUpdatePreview
{
    [self processMarkdownInTextStorage:textStorage
              syntaxHighlightCallbacks:shouldSyntaxHighlight
                         updatePreview:shouldUpdatePreview
            alignPreviewToTextPosition: -1];
}

- (void) processMarkdownInTextStorage: (NSTextStorage *) textStorage
             syntaxHighlightCallbacks: (BOOL)shouldSyntaxHighlight
                        updatePreview: (BOOL)shouldUpdatePreview
           alignPreviewToTextPosition: (NSInteger)position;
{
    if (!self.syntaxHighlighter) {
        NSLog(@"MarkdownProcessor: syntaxHighlighter is not set");
        return;
    }
    _syntaxHighlightArbiter.syntaxHighlighter = self.syntaxHighlighter;
    _syntaxHighlightArbiter.attributedText = textStorage;

    struct sd_callbacks callbacks;
    struct html_renderopt options;
    struct sd_markdown *markdown;

    const char *cstring = [textStorage.string UTF8String];
    struct buf *ib = bufnew(BUFFER_GROW_SIZE);
    bufputs(ib, cstring);

    BOOL shouldScroll = (shouldUpdatePreview && position >= 0);
    struct buf *ob = bufnew(BUFFER_GROW_SIZE);
    sdhtml_renderer(&callbacks, &options, 0);
    if (position >= 0) {
        options.cursor_pos = (size_t) position;
        options.cursor_marker_status = CURSOR_MARKER_YET_TO_BE_INSERTED;
    } else {
        options.cursor_pos = (size_t) 0;
        options.cursor_marker_status = CURSOR_MARKER_SHOULD_NOT_BE_INSERTED;
    }
    unsigned int md_extensions = (
                                  MKDEXT_TABLES |
                                  MKDEXT_FENCED_CODE |
                                  MKDEXT_AUTOLINK |
                                  MKDEXT_STRIKETHROUGH |
                                  MKDEXT_HIGHLIGHT |
                                  MKDEXT_FOOTNOTES |
                                  MKDEXT_LAX_SPACING |
                                  MKDEXT_TABLES
                                  );
    markdown = sd_markdown_new(md_extensions, 16, &callbacks, &options,
                               shouldSyntaxHighlight ? (__bridge void *) _syntaxHighlightArbiter : nil);

    sd_markdown_render(ob, ib->data, ib->size, markdown); // Would make calls on the syntaxHighlightArbiter internally
    sd_markdown_free(markdown);
    bufrelease(ib);

    if (!shouldUpdatePreview || _livePreviewDelegate == nil) {
        return;
    }

    if (_prev_ob == 0) {
        NSMutableString *js = [NSMutableString new];
        [js appendString:@""
         "var retVal = 0;"
         "try {"
         "    document.body.innerHTML = \'"
         ];
        appendHtmlToString(js,  ob->data, ob->size, /*nl_escaped*/ true);
        [js appendString:@"\';"
         "} catch (ex) {"
         "    retVal = 1" // ERROR_SETTING_INNERHTML
         "}"
         "retVal"
         ];
        [_livePreviewDelegate evaluateJavaScript:js completionHandler:^(id result, NSError *error) {
            if (error) {
                NSLog(@"Error sourcing loadHTML js: %@", error);
                return;
            }
        }];
        _prev_ob = ob;
        return;
    }
    NSTimeInterval delay = 0.0;
    if (_isLivePreviewUpdatePending) {
        // Drop any queued previous live-preview updates.
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        // Free DOM data about the last queued live-preview updates.
        bufreleasedom(_cur_ob);
        bufrelease(_cur_ob);
        _cur_ob = 0;
        // Delay live previewing of this change by a wee bit, to see if we have
        // more changes coming right after this one.
        delay = 0.3; // seconds
    }

    assert(_cur_ob == 0);
    _cur_ob = ob;
    _effectiveEditorCursorPos = -1;
    if ((shouldScroll == YES) && (options.cursor_marker_status == CURSOR_MARKER_IS_INSERTED)) {
        _effectiveEditorCursorPos = options.effective_cursor_pos;
    }
    _isLivePreviewUpdatePending = YES;

    [self performSelector:@selector(updateLivePreview) withObject:nil afterDelay:delay];
}

static void appendHtmlToString(NSMutableString *str, uint8_t* data, size_t length, bool nl_escaped);

- (NSString*)currentHtmlWithEscapedNewlines
{
    struct buf *ob = (_cur_ob ? _cur_ob : (_prev_ob ? _prev_ob : 0));
    if (ob) {
        NSMutableString *htmlStr = [NSMutableString new];
        appendHtmlToString(htmlStr, ob->data, ob->size, /*nl_escaped*/ true);
        return htmlStr;
    }
    return nil;
}

+ (NSString*)htmlForMarkdownInTextStorage:(NSTextStorage *) textStorage
{
    struct sd_callbacks callbacks;
    struct html_renderopt options;
    struct sd_markdown *markdown;

    const char *cstring = [textStorage.string UTF8String];
    struct buf *ib = bufnew(BUFFER_GROW_SIZE);
    bufputs(ib, cstring);

    struct buf *ob = bufnew(BUFFER_GROW_SIZE);
    sdhtml_renderer(&callbacks, &options, 0);
    options.cursor_pos = (size_t) 0;
    options.cursor_marker_status = CURSOR_MARKER_SHOULD_NOT_BE_INSERTED;
    unsigned int md_extensions = (
                                  MKDEXT_TABLES |
                                  MKDEXT_FENCED_CODE |
                                  MKDEXT_AUTOLINK |
                                  MKDEXT_STRIKETHROUGH |
                                  MKDEXT_HIGHLIGHT |
                                  MKDEXT_FOOTNOTES |
                                  MKDEXT_LAX_SPACING |
                                  MKDEXT_TABLES
                                  );
    markdown = sd_markdown_new(md_extensions, 16, &callbacks, &options, nil);

    sd_markdown_render(ob, ib->data, ib->size, markdown);
    sd_markdown_free(markdown);
    bufrelease(ib);
    NSString *htmlString = [[NSString alloc] initWithBytes:ob->data length:ob->size encoding:NSUTF8StringEncoding];
    bufrelease(ob);
    return htmlString;
}

#pragma mark - Internal methods

enum JavascriptCodeError {
    NO_ERROR = 0,
    ERROR_SETTING_INNERHTML = 1,
    ERROR_LOCATING_DOM_NODE = 2
};

static NSString* javascriptCodeToUpdateHtml(struct buf *fromHtml, struct buf *toHtml, BOOL applyOnDocumentBody);
void updateHtml(NSString *javascriptCode, id<LivePreviewDelegate> livePreviewDelegate, UITextView *textEditor, NSInteger effectiveCursorPos);
void scrollLivePreviewToEditPoint(id<LivePreviewDelegate> livePreviewDelegate, NSInteger effectiveCursorPos);

- (void) updateLivePreview
{
    if (_cur_ob == 0) {
        return;
    }
    NSString *js = javascriptCodeToUpdateHtml(_prev_ob, _cur_ob, NO /* Don't force applying on document.body */);
    if (js.length == 0) {
        bufreleasedom(_prev_ob);
        bufrelease(_prev_ob);
        _prev_ob = _cur_ob;
        _cur_ob = 0;
        _effectiveEditorCursorPos = -1;
        _isLivePreviewUpdatePending = NO;
        return;
    }
    [_livePreviewDelegate evaluateJavaScript:js completionHandler:^(id result, NSError *error) {
        if (error) {
            NSLog(@"Error sourcing domDiff js: %@", error);
            return;
        }
        int jsResult = ((NSNumber *)result).intValue;
        if (jsResult == ERROR_LOCATING_DOM_NODE) {
            // If there was a js error in finding the correct node to apply innerHTML on
            // (this is NOT expected to happen, but just in case we have a bug ...)
            // apply the whole HTML to document.body
            NSString *js2 = javascriptCodeToUpdateHtml(_prev_ob, _cur_ob, YES /* Force applying on document.body */);
            assert(js2.length > 0);
            [_livePreviewDelegate evaluateJavaScript:js2 completionHandler:^(id result2, NSError *error2) {
                // Don't bother about scrolling the live preview;
                // We're just trying to patch up a possible bug here.
                bufreleasedom(_prev_ob);
                bufrelease(_prev_ob);
                _prev_ob = _cur_ob;
                _cur_ob = 0;
                _effectiveEditorCursorPos = -1;
                _isLivePreviewUpdatePending = NO;
            }];
        } else {
            if (_effectiveEditorCursorPos >= 0) {
                scrollLivePreviewToEditPoint(_livePreviewDelegate, _effectiveEditorCursorPos);
            }
            bufreleasedom(_prev_ob);
            bufrelease(_prev_ob);
            _prev_ob = _cur_ob;
            _cur_ob = 0;
            _effectiveEditorCursorPos = -1;
            _isLivePreviewUpdatePending = NO;
        }
    }];
}

struct dom_node *locateDOMNode(struct dom_node *from_ast, struct dom_node *ast,
                               size_t location, size_t from_len, size_t len, size_t offset,
                               struct buf *traversal, size_t *cumulative_content_offset)
{
    // locateDOMNode:
    // Locates the node in the DOM such that fully contains
    // the range (location, from_len) in the from-DOM (i.e. from_ast)
    // and the range (location, len) in the to-DOM (i.e. ast).
    // Returns the node as it exists in the to-DOM, and populates
    // the traversal buffer with info on how to access it in both
    // the from-DOM or the to-DOM (it's the same for both DOMs).
    if (from_ast == 0 || ast == 0) {
        return 0;
    }
    if (from_ast->ambiguous_html_state == CONTAINING_AMBIGUOUS_HTML ||
        ast->ambiguous_html_state == CONTAINING_AMBIGUOUS_HTML) {
        // Bad or ambiguous HTML.
        // Can't be sure how WkWebView's DOM would look like past this node.
        return 0;
    }
    if (from_ast->content_offset != ast->content_offset) {
        return 0;
    }
    size_t co = offset + ast->content_offset;
    size_t from_co = offset + from_ast->content_offset;
    size_t to_cl = ast->content_length;
    size_t from_cl = from_ast->content_length;
    size_t cl = (from_cl < to_cl)? from_cl : to_cl;
    if (location >= co && location >= from_co) {
        if (((location + len) <= (co + cl)) && ((location + from_len) <= (from_co + from_cl))) {
            // check children
            size_t sz = traversal->size;
            bufputc(traversal, 'C');
            struct dom_node *node = locateDOMNode(from_ast->children, ast->children, location, from_len, len, co,
                                                  traversal, cumulative_content_offset);
            if (node) {
                return node;
            }
            traversal->size = sz;
            (*cumulative_content_offset) = co;
            return ast;
        } else {
            // check next
            bufputc(traversal, 'N');
            return locateDOMNode(from_ast->next, ast->next, location, from_len, len, offset,
                                 traversal, cumulative_content_offset);
        }
    }
    return 0;
}

static NSString* javascriptCodeToUpdateHtml(struct buf *fromHtml, struct buf *toHtml,
                                            BOOL applyOnDocumentBody)
{
    assert(toHtml);

    struct buf *traversal_info = 0;
    struct dom_node *dom_node = 0;
    size_t cumulative_content_offset = 0;

    if (fromHtml) {
        size_t len = fromHtml->size;
        if (len > toHtml->size) {
            len = toHtml->size;
        }

        size_t common_prefix_length = len;
        for (size_t i = 0; i < len; i++) {
            if (fromHtml->data[i] != toHtml->data[i]) {
                common_prefix_length = i;
                break;
            }
        }
        if (common_prefix_length > 0 && common_prefix_length < len && fromHtml->data[common_prefix_length - 1] == '<') {
            // Try not to match the '<'s in '</closingtag>' and '<openingtag>'
            common_prefix_length--;
        }

        size_t common_suffix_length = (len - common_prefix_length);
        for (size_t i = 0; i < (len - common_prefix_length); i++) {
            if (fromHtml->data[fromHtml->size - 1 - i] != toHtml->data[toHtml->size - 1 - i]) {
                common_suffix_length = i;
                break;
            }
        }

        size_t from_diff_len = fromHtml->size - common_suffix_length - common_prefix_length;
        size_t diff_len = toHtml->size - common_suffix_length - common_prefix_length;
        if (diff_len == 0 && fromHtml->size == toHtml->size) {
            return @"";
        }

        if (!applyOnDocumentBody) {
            traversal_info = bufnew(16);
            dom_node = locateDOMNode(fromHtml->dom, toHtml->dom, common_prefix_length, from_diff_len, diff_len, 0,
                                     traversal_info, &cumulative_content_offset);
        }

#ifdef DEBUG_JS_DIFF
        NSLog(@"\nFROM: \n\"%@\"", [[NSString alloc] initWithBytesNoCopy:fromHtml->data length:fromHtml->size encoding:NSUTF8StringEncoding freeWhenDone:false]);
        NSLog(@"\nTO  : \n\"%@\"", [[NSString alloc] initWithBytesNoCopy:toHtml->data length:toHtml->size encoding:NSUTF8StringEncoding freeWhenDone:false]);

        NSLog(@"Common prefix: \"%@\"", [[NSString alloc] initWithBytesNoCopy:toHtml->data length:common_prefix_length encoding:NSUTF8StringEncoding freeWhenDone:false]);
        NSLog(@"Mid FROM: \"%@\"", [[NSString alloc] initWithBytesNoCopy:(fromHtml->data + common_prefix_length) length:(fromHtml->size - common_suffix_length - common_prefix_length) encoding:NSUTF8StringEncoding freeWhenDone:false]);
        NSLog(@"Mid TO  : \"%@\"", [[NSString alloc] initWithBytesNoCopy:(toHtml->data + common_prefix_length) length:(toHtml->size - common_suffix_length - common_prefix_length) encoding:NSUTF8StringEncoding freeWhenDone:false]);
        NSLog(@"Common suffix: \"%@\"", [[NSString alloc] initWithBytesNoCopy:(toHtml->data + toHtml->size - common_suffix_length) length:common_suffix_length encoding:NSUTF8StringEncoding freeWhenDone:false]);

        if (dom_node) {
            NSLog(@"\nTraversal info: \"%@\"", [[NSString alloc] initWithBytesNoCopy:traversal_info->data length:traversal_info->size encoding:NSUTF8StringEncoding freeWhenDone:false]);
        } else {
            NSLog(@"\nTraversal info: Not Found");
        }
#endif
    }

    NSMutableString *js = [[NSMutableString alloc]
                           initWithString:@""
                           "var retVal = 0;"
                           "var e;"
                           "try {"
                           "    e = document.body"
                           ];

    if (dom_node) {
        assert(traversal_info);
        unsigned int n = 0;
        for (int i = 0; i < traversal_info->size; i++) {
            if (traversal_info->data[i] == 'C') {
                [js appendFormat:@".children[%d]", n];
                n = 0;
            } else if (traversal_info->data[i] == 'N') {
                n++;
            }
        }
        [js appendFormat:@".children[%d]", n];
    }
    [js appendString:@";"];

    [js appendString:@""
     "} catch (ex) {"
     "    e = undefined;"
     "}"
     ];

    [js appendFormat:@"if (e && e.tagName.toLowerCase() == \"%s\") {", (dom_node? dom_node->html_tag_name : "body")];

    size_t content_offset;
    size_t content_length;
    if (dom_node) {
        content_offset = cumulative_content_offset;
        content_length = dom_node->content_length;
    } else {
        content_offset = 0;
        content_length = toHtml->size;
    }

    [js appendString:@""
     "try {"
     "    e.innerHTML = \'"
     ];
    appendHtmlToString(js, toHtml->data + content_offset, content_length, /*nl_escaped*/ true);
    [js appendString:@"\';"
     "} catch (ex) {"
     "    retVal = 1" // ERROR_SETTING_INNERHTML
     "}"
     ];
    [js appendString:@""
     "} else {" // else of if (e && e.tagName() == "blah")
     "    retVal = 2" // ERROR_LOCATING_DOM_NODE
     "}"
     "retVal"
     ];

#ifdef DEBUG_JS_DIFF
    NSLog(@"\njs diff: \n\"%@\"", js);
#endif

    bufrelease(traversal_info);
    return js;
}

static void appendHtmlToString(NSMutableString *str, uint8_t* data, size_t length, bool nl_escaped)
{
    size_t i = 0;
    size_t p = 0;
    if (nl_escaped) {
        for (i = 0; i < length; i++) {
            if (data[i] == '\n') {
                NSString *substr = [[NSString alloc] initWithBytes:(data + p) length:(i - p) encoding:NSUTF8StringEncoding];
                if (substr) {
                    [str appendFormat:@"%@\\n", substr];
                }
                p = i + 1;
            }
        }
        if (i > p) {
            NSString *substr = [[NSString alloc] initWithBytes:(data + p) length:(i - p) encoding:NSUTF8StringEncoding];
            if (substr) {
                [str appendString:substr];
            }
        }
    } else {
        NSString *substr = [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
        if (substr) {
            [str appendString:substr];
        }
    }
}

void scrollLivePreviewToEditPoint(id<LivePreviewDelegate> livePreviewDelegate, NSInteger effectiveCursorPos)
{
    [livePreviewDelegate evaluateJavaScript:@"topOfCursorMarker()" completionHandler:^(id result, NSError *error) {
        if (error) {
            NSLog(@"Error calling topOfCursorMarker() in js: %@", error);
            return;
        }
        NSNumber *topOfCursorMarker = result;
        CGFloat previewCursorY = topOfCursorMarker.floatValue;
        CGFloat editorCursorY = [livePreviewDelegate topOfCaretAtEditorCursorPosition:effectiveCursorPos];
        CGFloat editorHeight = [livePreviewDelegate editorTextAreaHeight];
        CGFloat editorLineHeight = [livePreviewDelegate editorLineHeight];
        if (editorCursorY < 0) { // Editor will auto-scroll-down
            editorCursorY = 0;
        } else if (editorCursorY > editorHeight) { // Editor will auto-scroll-up
            editorCursorY = editorHeight - editorLineHeight;
        }
        CGFloat yDiff = (editorCursorY - previewCursorY);
        if ((previewCursorY < 0) ||
            (previewCursorY > (editorHeight - editorLineHeight)) || // FIXME: Assuming preview is same height as editor
            (abs(yDiff) > (editorLineHeight * 4))) {
            [livePreviewDelegate scrollVerticallyBy:yDiff];
        }
    }];
}

- (void)dealloc
{
    if (_isLivePreviewUpdatePending) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        bufreleasedom(_cur_ob);
        bufrelease(_cur_ob);
        _cur_ob = 0;
    }
    bufreleasedom(_prev_ob);
    bufrelease(_prev_ob);
    _prev_ob = 0;
}

@end
