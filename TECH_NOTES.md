
## Syntax Highlighting anomalies

Redcarpet does a "rewind" for autolinking emails and http URLs. That is,
it realizes that it could be an autolink only when it sees the `@` in
the email or the `:` in the http URL. So in the string:

    Contact me at me@myself.net

Redcarpet first thinks `Contact me at me` is a normal string, and our
syntax highlighter calls back saying that, so our SyntaxHighlightArbiter
stores that as the syntax highlight data in the NSAttributedString.

Then, once Redcarpet notices the `@`, it says that `me` should be part
of the link, and so our syntax highlighter calls back for that part
of the text with a different syntax highlight data. This means that
the SyntaxHighlightArbiter will always consider these parts as requiring
calls to the SyntaxHighlighter class because it would always think 
that part has changed, even though it hasn't.

