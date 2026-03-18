# This pygments lexer is an exact copy of lexer found in:
#     docs/conf.py of https://github.com/nextflow-io/nextflow repository (commit a2e67eb)
#     https://github.com/nextflow-io/nextflow/blob/a2e67eb9982ef05494a12b9ead8911bbaf7f8af2/docs/conf.py#L357
#
# License: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
#          (same as the license of Nextflow documentation)

import re
from pygments.lexer import bygroups, using, this, default, RegexLexer
from pygments.token import Comment, Operator, Keyword, Name, String, Number, Whitespace
from pygments.util import shebang_matches

class NextflowLexer(RegexLexer):
    """
    For Nextflow source code.
    """

    name = 'Nextflow'
    url = 'https://nextflow.io/'
    aliases = ['nextflow', 'nf']
    filenames = ['*.nf']
    mimetypes = ['text/x-nextflow']
    # version_added = '1.5'

    flags = re.MULTILINE | re.DOTALL

    tokens = {
        'root': [
            # Nextflow allows a file to start with a shebang
            (r'#!(.*?)$', Comment.Preproc, 'base'),
            default('base'),
        ],
        'base': [
            (r'[^\S\n]+', Whitespace),
            (r'(//.*?)(\n)', bygroups(Comment.Single, Whitespace)),
            (r'/\*.*?\*/', Comment.Multiline),
            # keywords: go before method names to avoid lexing "throw new XYZ"
            # as a method signature
            (r'(assert|catch|else|if|instanceof|new|return|throw|try|in|as)\b', Keyword),
            (r'(channel|log)', Name.Namespace),
            # method names
            (r'^(\s*(?:[a-zA-Z_][\w.\[\]]*\s+)+?)'  # return arguments
             r'('
             r'[a-zA-Z_]\w*'                        # method name
             r'|"(?:\\\\|\\[^\\]|[^"\\])*"'         # or double-quoted method name
             r"|'(?:\\\\|\\[^\\]|[^'\\])*'"         # or single-quoted method name
             r')'
             r'(\s*)(\()',                          # signature start
             bygroups(using(this), Name.Function, Whitespace, Operator)),
            (r'@[a-zA-Z_][\w.]*', Name.Decorator),
            (r'(def|enum|include|from|output|params|process|workflow)\b', Keyword.Declaration),
            (r'(boolean|byte|char|double|float|int|long|short|void)\b', Keyword.Type),
            (r'(true|false|null)\b', Keyword.Constant),
            (r'""".*?"""', String.Double),
            (r"'''.*?'''", String.Single),
            (r'"(\\\\|\\[^\\]|[^"\\])*"', String.Double),
            (r"'(\\\\|\\[^\\]|[^'\\])*'", String.Single),
            (r'/(\\\\|\\[^\\]|[^/\\])*/', String),
            (r"'\\.'|'[^\\]'|'\\u[0-9a-fA-F]{4}'", String.Char),
            (r'(\.)([a-zA-Z_]\w*)', bygroups(Operator, Name.Attribute)),
            (r'[a-zA-Z_]\w*:', Name.Label),
            (r'[a-zA-Z_$]\w*', Name),
            (r'[~^*!%&\[\](){}<>|+=:;,./?-]', Operator),
            (r'[0-9][0-9]*\.[0-9]+([eE][0-9]+)?[fd]?', Number.Float),
            (r'0x[0-9a-fA-F]+', Number.Hex),
            (r'[0-9]+L?', Number.Integer),
            (r'\n', Whitespace)
        ],
    }

    def analyse_text(text):
        return shebang_matches(text, r'nextflow')
