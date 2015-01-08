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

- (void) processMarkdownInTextStorage:(NSTextStorage *) textStorage withCursorPosition: (NSUInteger) position;
{
    assert(position >= 0);

    if (!self.syntaxHighlighter) {
        self.syntaxHighlighter = [SyntaxHighlighter new];
    }
    _syntaxHighlightArbiter.syntaxHighlighter = self.syntaxHighlighter;
    _syntaxHighlightArbiter.attributedText = textStorage;

    struct sd_callbacks callbacks;
    struct html_renderopt options;
    struct sd_markdown *markdown;

    const char *cstring = [textStorage.string UTF8String];
    struct buf *ib = bufnew(BUFFER_GROW_SIZE);
    bufputs(ib, cstring);

    struct buf *ob = bufnew(BUFFER_GROW_SIZE);
    sdhtml_renderer(&callbacks, &options, 0);
    options.cursor_pos = (size_t) position;
    options.cursor_marker_status = CURSOR_MARKER_YET_TO_BE_INSERTED;
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
    markdown = sd_markdown_new(md_extensions, 16, &callbacks, &options, (__bridge void *) _syntaxHighlightArbiter);

    sd_markdown_render(ob, ib->data, ib->size, markdown); // Would make calls on the syntaxHighlightDelegate internally
    sd_markdown_free(markdown);
    bufrelease(ib);

    if (_prev_ob == 0) {
        NSString *html = [[NSString alloc] initWithBytes:ob->data length:ob->size encoding:NSUTF8StringEncoding];
        NSString *preHtml = @""
        "<html>"
        "<head>"
        "<meta name=\"viewport\" content=\"initial-scale=1.0, maximum-scale=1.0, user-scalable=no\" />"
        "<style>%s</style>"
        "<script>"
        "function topOfCursorMarker() {"
        "    return (document.getElementById(\"__cursor_marker__\").getClientRects()[0]).top;"
        "}"
        "</script>"
        "</head>"
        "<body style=\"font-size: 16;\">";
        NSString *postHtml = @""
        "</body>"
        "</html>";
        NSString *full = [preHtml stringByAppendingFormat:@"%@%@", html, postHtml];
        [_livePreviewDelegate loadHTMLAfterInsertingCSS:full];
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
    _effectiveEditorCursorPos = ((options.cursor_marker_status == CURSOR_MARKER_IS_INSERTED)? options.effective_cursor_pos : -1);
    _isLivePreviewUpdatePending = YES;

    [self performSelector:@selector(updateLivePreview) withObject:nil afterDelay:delay];
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
                               size_t location, size_t len, size_t offset,
                               struct buf *traversal, size_t *cumulative_content_offset)
{
    if (ast == 0) {
        return 0;
    }
    if (ast->ambiguous_html_state == CONTAINING_AMBIGUOUS_HTML) {
        // Bad or ambiguous HTML.
        // Can't be sure how WkWebView's DOM would look like past this node.
        return 0;
    }
    if (from_ast == 0 || ast == 0) {
        return 0;
    }
    if (from_ast->content_offset != ast->content_offset) {
        return 0;
    }
    size_t co = offset + ast->content_offset;
    size_t to_cl = ast->content_length;
    size_t from_cl = from_ast->content_length;
    size_t cl = (from_cl < to_cl)? from_cl : to_cl;
    if (location >= co) {
        if ((location + len) <= (co + cl)) {
            // check children
            size_t sz = traversal->size;
            bufputc(traversal, 'C');
            struct dom_node *node = locateDOMNode(from_ast->children, ast->children, location, len, co,
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
            return locateDOMNode(from_ast->next, ast->next, location, len, offset,
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

        size_t diff_len = toHtml->size - common_suffix_length - common_prefix_length;
        if (diff_len == 0 && fromHtml->size == toHtml->size) {
            return @"";
        }

        if (!applyOnDocumentBody) {
            traversal_info = bufnew(16);
            dom_node = locateDOMNode(fromHtml->dom, toHtml->dom, common_prefix_length, diff_len, 0,
                                     traversal_info, &cumulative_content_offset);
        }
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
    size_t i, p = content_offset;
    for (i = content_offset; i < (content_offset + content_length); i++) {
        if (toHtml->data[i] == '\n') {
            [js appendFormat:@"%@\\n", [[NSString alloc] initWithBytes:(toHtml->data + p) length:(i - p)
                                                              encoding:NSUTF8StringEncoding]];
            p = i + 1;
        }
    }
    if (i > p) {
        NSString *str = [[NSString alloc] initWithBytes:(toHtml->data + p) length:(i - p)
                                               encoding:NSUTF8StringEncoding];
        if (str) {
            [js appendString:str];
        }
    }
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

    bufrelease(traversal_info);
    return js;
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
