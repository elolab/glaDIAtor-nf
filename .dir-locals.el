((org-mode
  (org-latex-packages-alist
   ("newfloat" "minted"))
  (org-latex-listings . minted)
  (org-latex-pdf-process "latexmk -shell-escape -f -pdf -%latex -interaction=nonstopmode -output-directory=%o %f")
  (org-latex-minted-langs
   (emacs-lisp "common-lisp")
   (cc "c++")
   (cperl "perl")
   (shell-script "bash")
   (caml "ocaml")
   (nextflow "groovy"))
  (org-babel-load-languages
   ((dot . t)))
  (org-html-htmlize-output-type . css)
  (org-html-head . "<style type=\"text/css\">\n    <!--\n      body {\n        color: #000000;\n        background-color: #ffffff;\n      }\n      .org-bold {\n        /* bold */\n        font-weight: bold;\n      }\n      .org-builtin {\n        /* font-lock-builtin-face */\n        color: #8f0075;\n      }\n      .org-comment {\n        /* font-lock-comment-face */\n        color: #505050;\n      }\n      .org-comment-delimiter {\n        /* font-lock-comment-delimiter-face */\n        color: #505050;\n      }\n      .org-constant {\n        /* font-lock-constant-face */\n        color: #0000c0;\n      }\n      .org-default {\n        /* default */\n        color: #000000;\n        background-color: #ffffff;\n      }\n      .org-doc {\n        /* font-lock-doc-face */\n        color: #2a486a;\n      }\n      .org-ess-assignment {\n        /* ess-assignment-face */\n        color: #0000c0;\n      }\n      .org-ess-constant {\n        /* ess-constant-face */\n        color: #005a5f;\n      }\n      .org-ess-keyword {\n        /* ess-keyword-face */\n        color: #5317ac;\n      }\n      .org-ess-modifiers {\n        /* ess-modifiers-face */\n        color: #0000c0;\n      }\n      .org-function-name {\n        /* font-lock-function-name-face */\n        color: #721045;\n      }\n      .org-keyword {\n        /* font-lock-keyword-face */\n        color: #5317ac;\n      }\n      .org-nxml-attribute-local-name {\n        /* nxml-attribute-local-name */\n        color: #00538b;\n      }\n      .org-nxml-element-local-name {\n        /* nxml-element-local-name */\n        color: #721045;\n      }\n      .org-nxml-processing-instruction-content {\n        /* nxml-processing-instruction-content */\n        color: #093060;\n      }\n      .org-nxml-processing-instruction-delimiter {\n        /* nxml-processing-instruction-delimiter */\n        color: #282828;\n      }\n      .org-nxml-processing-instruction-target {\n        /* nxml-processing-instruction-target */\n        color: #5317ac;\n      }\n      .org-nxml-tag-delimiter {\n        /* nxml-tag-delimiter */\n        color: #282828;\n      }\n      .org-nxml-tag-slash {\n        /* nxml-tag-slash */\n        color: #282828;\n      }\n      .org-nxml-text {\n      }\n      .org-org-block {\n        /* org-block */\n        color: #000000;\n      }\n      .org-org-block-begin-line {\n        /* org-block-begin-line */\n        color: #505050;\n        background-color: #f0f0f0;\n      }\n      .org-org-block-end-line {\n        /* org-block-end-line */\n        color: #505050;\n        background-color: #f0f0f0;\n      }\n      .org-org-checkbox-statistics-done {\n        /* org-checkbox-statistics-done */\n        color: #005e00;\n      }\n      .org-org-code {\n        /* org-code */\n        color: #005a5f;\n      }\n      .org-org-date {\n        /* org-date */\n        color: #00538b;\n        text-decoration: underline;\n      }\n      .org-org-done {\n        /* org-done */\n        color: #005e00;\n      }\n      .org-org-drawer {\n        /* org-drawer */\n        color: #505050;\n      }\n      .org-org-headline-done {\n        /* org-headline-done */\n        color: #004000;\n      }\n      .org-org-level-1 {\n        /* org-level-1 */\n        color: #000000;\n        font-weight: bold;\n      }\n      .org-org-level-2 {\n        /* org-level-2 */\n        color: #5d3026;\n        font-weight: bold;\n      }\n      .org-org-level-3 {\n        /* org-level-3 */\n        color: #093060;\n        font-weight: bold;\n      }\n      .org-org-level-4 {\n        /* org-level-4 */\n        color: #184034;\n        font-weight: bold;\n      }\n      .org-org-link {\n        /* org-link */\n        color: #0000c0;\n        text-decoration: underline;\n      }\n      .org-org-meta-line {\n        /* org-meta-line */\n        color: #505050;\n      }\n      .org-org-property-value {\n        /* org-property-value */\n        color: #093060;\n      }\n      .org-org-special-keyword {\n        /* org-special-keyword */\n        color: #505050;\n      }\n      .org-org-table {\n        /* org-table */\n        color: #093060;\n      }\n      .org-org-tag {\n        /* org-tag */\n        color: #541f4f;\n      }\n      .org-org-verbatim {\n        /* org-verbatim */\n        color: #8f0075;\n      }\n      .org-sh-quoted-exec {\n        /* sh-quoted-exec */\n        color: #8f0075;\n      }\n      .org-string {\n        /* font-lock-string-face */\n        color: #2544bb;\n      }\n      .org-type {\n        /* font-lock-type-face */\n        color: #005a5f;\n      }\n      .org-underline {\n        /* underline */\n        text-decoration: underline;\n      }\n      .org-variable-name {\n        /* font-lock-variable-name-face */\n        color: #00538b;\n      }\n\n      a {\n        color: inherit;\n        background-color: inherit;\n        font: inherit;\n        text-decoration: inherit;\n      }\n      a:hover {\n        text-decoration: underline;\n      }\n    -->\n    </style>\n")))
