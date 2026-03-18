import os
import sys

sys.path.insert(0, os.path.abspath('.'))

from extensions.nextflow_lexer import NextflowLexer

project = 'gladiator-nf'
copyright = '2026, Mats Perk, Sami Pietilä, Tommi Välikangas, Balázs Bálint, Tomi Suomi, Laura Elo'
author = 'Mats Perk, Sami Pietilä, Tommi Välikangas, Balázs Bálint, Tomi Suomi, Laura Elo'

extensions = [ 'myst_parser', 'sphinx.ext.graphviz', 'sphinx_design', 'sphinxcontrib.bibtex' ]
myst_enable_extensions = [ 'colon_fence', 'deflist', 'dollarmath' ]

graphviz_output_format = 'svg'
graphviz_dot = 'dot'

bibtex_bibfiles = ['../user-guide/publications.bib']
bibtex_default_style = 'unsrt'

html_show_sourcelink = False

exclude_patterns = [ '**/site-packages/**', '**/.pytest_cache/**', '.venv', 'dist', 'README.md' ]

html_theme = 'pydata_sphinx_theme'
html_static_path = [ 'assets' ]

html_css_files = [
    'pydata.css'
]

html_theme_options = {
    'logo': {
        'image_light': 'assets/gladiator-icon.png',
        'image_dark': 'assets/gladiator-icon.png',
    },
    "icon_links": [
        {
            "name": "GitHub",
            "url": "https://github.com/elolab/glaDIAtor-nf",
            "icon": "fa-brands fa-square-github",
            "type": "fontawesome",
        }
    ],
    'pygments_light_style': 'tango',
    'pygments_dark_style': 'monokai',
    'footer_start': [ 'copyright' ], 'footer_end': [ ],
}

def setup(app):
    app.add_lexer('nextflow', NextflowLexer)
