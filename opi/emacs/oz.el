;;;
;;; Authors:
;;;   Leif Kornstaedt <kornstae@ps.uni-sb.de>
;;;   Michael Mehl <mehl@ps.uni-sb.de>
;;;   Ralf Scheidhauer <scheihr@ps.uni-sb.de>
;;;
;;; Contributor:
;;;   Benjamin Lorenz <lorenz@ps.uni-sb.de>
;;;   Denys Duchier <duchier@ps.uni-sb.de>
;;;
;;; Copyright:
;;;   Leif Kornstaedt, Michael Mehl, and Ralf Scheidhauer, 1993-1998
;;;   Denys Duchier, 1998
;;;
;;; Last change:
;;;   $Date$ by $Author$
;;;   $Revision$
;;;
;;; This file is part of Mozart, an implementation of Oz 3:
;;;   http://www.mozart-oz.org
;;;
;;; See the file "LICENSE" or
;;;   http://www.mozart-oz.org/LICENSE.html
;;; for information on usage and redistribution
;;; of this file, and for a DISCLAIMER OF ALL
;;; WARRANTIES.
;;;

;; Major mode for editing Oz programs
;;

;;{{{ Global Effects

(or (member ".ozp" completion-ignored-extensions)
    (setq completion-ignored-extensions
          (append '(".ozp" ".ozf" ".oza") completion-ignored-extensions)))

(or (assoc "\\.oz$" auto-mode-alist)
    (setq auto-mode-alist
          (append '(("\\.oz$" . oz-mode)
                    ("\\.ozm$" . ozm-mode)
                    ("\\.ozg$" . oz-gump-mode))
                  auto-mode-alist)))

(autoload 'ozm-mode "mozart"
  "Major mode for displaying Oz machine code." t)
(autoload 'oz-feed-buffer "mozart"
  "Feed the current buffer to the Oz Compiler." t)
(autoload 'oz-feed-region "mozart"
  "Feed the current region to the Oz Compiler." t)
(autoload 'oz-feed-line "mozart"
  "Feed the current line to the Oz Compiler." t)
(autoload 'oz-feed-paragraph "mozart"
  "Feed the current paragraph to the Oz Compiler." t)
(autoload 'oz-feed-file "mozart"
  "Feed a file to the Oz Compiler." t)
(autoload 'oz-compile-file "mozart"
  "Compile an Oz program non-interactively." t)
(autoload 'oz-to-coresyntax-buffer "mozart"
  "Display the core syntax expansion of the current buffer." t)
(autoload 'oz-to-coresyntax-region "mozart"
  "Display the core syntax expansion of the current region." t)
(autoload 'oz-to-coresyntax-line "mozart"
  "Display the core syntax expansion of the current line." t)
(autoload 'oz-to-coresyntax-paragraph "mozart"
  "Display the core syntax expansion of the current paragraph." t)
(autoload 'oz-to-emulatorcode-buffer "mozart"
  "Display the emulator code for the current buffer." t)
(autoload 'oz-to-emulatorcode-region "mozart"
  "Display the emulator code for the current region." t)
(autoload 'oz-to-emulatorcode-line "mozart"
  "Display the emulator code for the current line." t)
(autoload 'oz-to-emulatorcode-paragraph "mozart"
  "Display the emulator code for the current paragraph." t)
(autoload 'oz-browse-buffer "mozart"
  "Feed the current buffer to the Oz Compiler." t)
(autoload 'oz-browse-region "mozart"
  "Feed the current region to the Oz Compiler." t)
(autoload 'oz-browse-line "mozart"
  "Feed the current line to the Oz Compiler." t)
(autoload 'oz-browse-paragraph "mozart"
  "Feed the current paragraph to the Oz Compiler." t)
(autoload 'oz-show-buffer "mozart"
  "Feed the current buffer to the Oz Compiler." t)
(autoload 'oz-show-region "mozart"
  "Feed the current region to the Oz Compiler." t)
(autoload 'oz-show-line "mozart"
  "Feed the current line to the Oz Compiler." t)
(autoload 'oz-show-paragraph "mozart"
  "Feed the current paragraph to the Oz Compiler." t)
(autoload 'oz-inspect-buffer "mozart"
  "Feed the current buffer to the Oz Compiler." t)
(autoload 'oz-inspect-region "mozart"
  "Feed the current region to the Oz Compiler." t)
(autoload 'oz-inspect-line "mozart"
  "Feed the current line to the Oz Compiler." t)
(autoload 'oz-inspect-paragraph "mozart"
  "Feed the current paragraph to the Oz Compiler." t)
(autoload 'oz-open-panel "mozart"
  "Feed `{Panel.open}' to the Oz Compiler." t)
(autoload 'oz-open-compiler-panel "mozart"
  "Feed `{Panel.open}' to the Oz Compiler." t)
(autoload 'oz-open-distribution-panel "mozart"
  "Feed `{DistributionPanel.open}' to the Oz Compiler." t)
(autoload 'oz-debugger "mozart"
  "Start the Oz debugger." t)
(autoload 'oz-debug-application "mozart"
  "Invoke ozd." t)
(autoload 'oz-profiler "mozart"
  "Start the profiler." t)
(autoload 'oz-toggle-compiler "mozart"
  "Toggle visibility of the Oz Compiler window." t)
(autoload 'oz-toggle-emulator "mozart"
  "Toggle visibility of the Oz Emulator window." t)
(autoload 'oz-toggle-temp "mozart"
  "Toggle visibility of the Oz Temp window." t)
(autoload 'run-oz "mozart"
  "Run Mozart as a sub-process." t)
(autoload 'oz-halt "mozart"
  "Halt the Mozart sub-process." t)
(autoload 'oz-attach "mozart"
  "" t)
(autoload 'oz-breakpoint-at-point "mozart"
  "Set breakpoint at current line." t)
(autoload 'oz-is-running "mozart" "" nil)

;;}}}
;;{{{ GNU and Lucid Emacsen Support

(eval-and-compile
  (defvar oz-gnu-emacs
    (string-match "\\`[0-9]+\\(\\.[0-9]+\\)*\\'" emacs-version)
    "Non-nil iff we're running under GNU Emacs.")
  (defvar oz-lucid-emacs
    (string-match "\\<XEmacs\\>\\|\\<Lucid\\>" emacs-version)
    "Non-nil iff we're running under XEmacs."))

;;}}}
;;{{{ Customization

(put 'oz 'custom-loads '("mozart"))

(eval-and-compile
  (condition-case ()
      (require 'custom)
    (error nil))
  (if (and (featurep 'custom)
           (fboundp 'custom-declare-variable)
           (fboundp 'custom-declare-group))
      nil
    (defmacro defgroup (&rest args)
      nil)
    (defmacro defcustom (symbol value doc &rest args)
      `(defvar ,symbol ,value ,doc))))

(eval-and-compile
  (eval '(defgroup oz nil
           "Oz Programming Interface."
           :group 'languages
           :prefix "oz-")))

(eval-and-compile
  (eval '(defcustom oz-mode-hook nil
           "*Functions to run when Oz Mode or Oz-Gump Mode is activated."
           :type 'hook
           :group 'oz)))

(eval-and-compile
  (eval '(defcustom oz-want-font-lock t
           "*If non-nil, automatically enter font-lock-mode for the Oz modes."
           :type 'boolean
           :group 'oz)))
(put 'oz-want-font-lock 'variable-interactive
     "XAutomatically enter font-lock-mode in the Oz modes? (t or nil): ")

(eval-and-compile
  (eval '(defcustom oz-auto-indent t
           "*If non-nil, automatically indent lines."
           :type 'boolean
           :group 'oz)))
(put 'oz-auto-indent 'variable-interactive
     "XAutomatically indent lines in Oz and Oz-Gump modes? (t or nil): ")

(eval-and-compile
  (eval '(defcustom oz-indent-chars 3
           "*Number of columns statements are indented wrt. containing block."
           :type 'integer
           :group 'oz)))
(put 'oz-indent-chars 'variable-interactive
     "nNumber of characters to indent in Oz and Oz-Gump modes: ")

(eval-and-compile
  (eval '(defcustom oz-pedantic-spaces nil
           "*If non-nil, highlight ill-placed whitespace.
Note that this variable is only checked once when oz.el is loaded."
           :type 'boolean
           :group 'oz)))
(put 'oz-pedantic-spaces 'variable-interactive
     "XHighlight ill-spaced whitespace? (t or nil): ")


;;}}}
;;{{{ Faces

(defvar oz-is-color
  (and (or (eq window-system 'x)
           (eq window-system 'w32))
       (x-display-color-p)))

(make-face 'oz-space-face)
(put 'oz-space-face 'face-documentation
     "Face in which ill-placed whitespace is highlighted.")
(set-face-background 'oz-space-face (if oz-is-color "hotpink" "black"))
(defvar oz-space-face 'oz-space-face
  "Face in which ill-placed whitespace is highlighted.")

;;}}}
;;{{{ Patterns for Indentation and Expression Hopping

(defvar oz-gump-indentation nil
  "Non-nil iff Gump syntax is to be used for indentation.")

(defun oz-make-keywords-for-match (args)
  (concat "\\<\\(" (if (fboundp 'regexp-opt)
                       (regexp-opt args)
                     (mapconcat 'regexp-quote args "\\|"))
          "\\)\\>"))

(defconst oz-declare-pattern
  (oz-make-keywords-for-match '("declare")))

(defconst oz-class-begin-pattern
  (oz-make-keywords-for-match
   '("class" "functor")))
(defconst oz-gump-class-begin-pattern
  (oz-make-keywords-for-match
   '("scanner" "parser")))

(defconst oz-class-member-pattern
  (oz-make-keywords-for-match
   '("meth")))
(defconst oz-gump-class-member-pattern
  (oz-make-keywords-for-match
   '("lex" "mode" "prod" "syn")))

(defconst oz-class-between-pattern
  (oz-make-keywords-for-match
   '("from" "prop" "attr" "feat")))
(defconst oz-gump-class-between-pattern
  (oz-make-keywords-for-match
   '("token")))

(defconst oz-begin-pattern
  (concat
   (oz-make-keywords-for-match
    '("local" "proc" "fun" "case" "if" "cond" "or" "dis" "choice" "not"
      "thread" "try" "raise" "lock" "for"))
   "\\|<<"))

(defconst oz-gump-between-pattern
  "=>")

(defconst oz-middle-pattern
  (concat (oz-make-keywords-for-match
           '("in" "then" "else" "of" "elseof" "elsecase" "elseif"
             "catch" "finally" "with" "require" "prepare" "import" "export"
             "define" "do"))
          "\\|" "\\[\\]"))
(defconst oz-gump-middle-pattern
  "//")

(defconst oz-end-pattern
  (concat (oz-make-keywords-for-match '("end")) "\\|>>"))

(defconst oz-left-pattern
  "\\[\\($\\|[^]]\\)\\|[({\253]\\|<<")
(defconst oz-right-pattern
  "[])}\273]\\|>>")
(defconst oz-left-or-right-pattern
  "[][(){}\253\273]\\|<<\\|>>")

(defconst oz-any-pattern
  (concat "\\<\\(at\\|attr\\|case\\|catch\\|class\\|choice\\|cond\\|"
          "declare\\|define\\|do\\|dis\\|else\\|elsecase\\|elseif\\|"
          "elseof\\|end\\|export\\|feat\\|finally\\|for\\|from\\|fun\\|functor\\|"
          "if\\|in\\|import\\|local\\|lock\\|meth\\|not\\|of\\|or\\|prepare\\|"
          "proc\\|prop\\|raise\\|require\\|then\\|thread\\|try\\)\\>\\|"
          "\\[\\]\\|"
          oz-left-or-right-pattern))
(defconst oz-gump-any-pattern
  (concat "\\<\\(at\\|attr\\|case\\|catch\\|class\\|choice\\|cond\\|"
          "declare\\|define\\|do\\|dis\\|else\\|elsecase\\|elseif\\|"
          "elseof\\|end\\|export\\|feat\\|finally\\|for\\|from\\|fun\\|functor\\|"
          "if\\|in\\|import\\|lex\\|local\\|lock\\|meth\\|mode\\|not\\|of\\|"
          "or\\|parser\\|prepare\\|proc\\|prod\\|prop\\|raise\\|require\\|"
          "scanner\\|syn\\|then\\|thread\\|token\\|try\\)\\>\\|=>\\|"
          "\\[\\]\\|"
          "//\\|" oz-left-or-right-pattern))

;;}}}
;;{{{ Moving Among Oz Expressions

(defun oz-forward-keyword ()
  "Search forward for the next keyword or parenthesis following point.
Return non-nil iff such a keyword was found.  Ignore quoted keywords.
Point is left at the first character of the keyword."
  (let ((pattern (if oz-gump-indentation oz-gump-any-pattern oz-any-pattern))
        (continue t)
        (ret nil))
    (while continue
      (if (re-search-forward pattern nil t)
          (save-match-data
            (goto-char (match-beginning 0))
            (cond ((oz-is-quoted)
                   (goto-char (match-end 0)))
                  ((oz-is-directive)
                   (forward-line))
                  (t
                   (setq ret t continue nil))))
        (setq continue nil)))
    ret))

(defun oz-backward-keyword ()
  "Search backward for the last keyword or parenthesis preceding point.
Return non-nil iff such a keyword was found.  Ignore quoted keywords.
Point is left at the first character of the keyword."
  (let ((pattern (if oz-gump-indentation oz-gump-any-pattern oz-any-pattern))
        (continue t)
        (ret nil))
    (while continue
      (if (re-search-backward pattern nil t)
          (cond ((oz-is-quoted) t)
                ((oz-is-directive) t)
                ((oz-is-box)
                 (setq ret t continue nil))
                (t
                 (setq ret t continue nil)))
        (setq continue nil)))
    ret))

;; Note: The following do not allow for newlines inside quoted tokens
;; to make matching easier ...
;; Furthermore, `/*' ... `*/' style comments are not included here
;; because of the problems of nesting and line breaks.
(defconst oz-string-pattern
  "\"\\([^\"\C-@\\\n]\\|\\\\.\\)*\"")
(defconst oz-atom-pattern
  "'\\([^'\C-@\\\n]\\|\\\\.\\)*'")
(defconst oz-variable-pattern
  "`\\([^`\C-@\\\n]\\|\\\\.\\)*`")
(defconst oz-char-pattern
  "&\\([^\C-@\\\n]\\|\\\\.\\)")
(defconst oz-comment-pattern
  "%.*")
(defconst oz-quoted-pattern
  (concat oz-string-pattern "\\|" oz-atom-pattern "\\|"
          oz-variable-pattern "\\|" oz-char-pattern "\\|"
          oz-comment-pattern))

(defconst oz-atom-or-variable-char
  "A-Z\300-\326\330-\336a-z\337-\366\370-\3770-9_")

(defconst oz-atom-or-variable-or-quote-pattern
  (concat "[" oz-atom-or-variable-char "']"))

(defconst oz-gump-regex-matcher
  (concat
   "\\<lex[^" oz-atom-or-variable-char "\n][^<\"\n]*"
   "\\(<\\("
   "\\[\\([^]\\]\\|\\\\.\\)+\\]" "\\|"
   "\"[^\"\n]+\"" "\\|"
   "\\\\." "\\|"
   "[^]<>\"[\\\n]" "\\)+"
   ">\\|<<EOF>>\\)"))

(defconst oz-number-pattern
  (concat "~?\\(0[Xx][0-9A-Fa-f]+\\|0[bB][01]+\\|"
          "[0-9]+\\(\\.[0-9]*\\([eE]~?[0-9]+\\)?\\)?\\)")
  "Regular expression matching an Oz number; used by oz-bar.")
(defconst oz-token-pattern
  (concat oz-atom-pattern "(?" "\\|" oz-string-pattern "\\|"
          oz-variable-pattern "(?" "\\|" oz-char-pattern "\\|"
          oz-number-pattern "\\|"
          "[A-Za-z][A-Za-z0-9_]*(?\\|"
          "\\[\\]\\|\\.\\.\\.\\|<-\\|<=\\|:=\\|!!\\|=<\\|>=\\|\\\\=\\|"
          ":::?\\|==\\|[<>]:\\|=<:\\|>=:\\|=:\\|"
          "[+<>*/{}()|#:=.^@$!~_,]\\|\\[\\|\\]\\|\\-")
  "Matches a single Oz token; used by oz-bar.")

(defconst oz-directive-pattern
  "\\\\[a-zA-Z]+")
(defconst oz-directives-to-indent
  (concat "\\\\\\("
          "in\\|ins\\|inse\\|inser\\|insert\\|l\\|li\\|lin\\|line\\|"
          "gumpscannerprefix\\|gumpparserexpect"
          "\\)\\>"))

(defun oz-is-quoted ()
  "Return non-nil iff the position of point is quoted.
Return non-nil iff point is inside a string, quoted atom, backquote
variable, ampersand-denoted character or one-line comment.  In this
case, move point to the beginning of the corresponding token.  Else
point is not moved."
  (let ((ret nil)
        (p (point))
        cont-point)
    (beginning-of-line)
    (while (and (not ret)
                (prog1
                    (re-search-forward "[\"'`&%]\\|lex\\|$" nil t)
                  (setq cont-point (match-end 0))
                  (goto-char (match-beginning 0)))
                (< (point) p))
      (cond ((looking-at oz-quoted-pattern)
             (let ((quote-end (match-end 0)))
               (if (< p quote-end)
                   (setq ret t)
                 (goto-char quote-end))))
            ((and oz-gump-indentation
                  (looking-at oz-gump-regex-matcher))
             (let ((quote-end (match-end 0)))
               (if (< p quote-end)
                   (progn
                     (forward-char 3)
                     (setq ret t))
                 (goto-char quote-end))))
            ((looking-at "\"")
             (error
              "Illegal string syntax or unterminated string"))
            ((looking-at "'")
             (error
              "Illegal atom syntax or unterminated quoted atom"))
            ((looking-at "`")
             (error
              "Illegal variable syntax or unterminated backquote variable"))
            (t (goto-char cont-point))))
    (if (not ret) (goto-char p))
    ret))

(defun oz-is-directive ()
  ;; Return non-nil iff the point is one char after the start of a directive.
  ;; That means, if the point is at a keyword-lookalike and preceded by a
  ;; backslash.  If yes, the point is moved to the backslash.
  (let ((p (point)))
    (if (= p (point-min))
        t
      (backward-char))
    (if (looking-at oz-directive-pattern)
        t
      (goto-char p)
      nil)))

(defun oz-is-box ()
  ;; Return non-nil if point is at the second character of a `[]' token.
  ;; In this case, move point to the first character of this token.
  (let ((p (point)))
    (if (= p (point-min))
        t
      (backward-char))
    (if (and (looking-at "\\[\\]")
             (not (oz-is-quoted)))   ; consider the list '[&[]'!
        t
      (goto-char p)
      nil)))

;;}}}
;;{{{ Moving to Expression Boundaries

(defun oz-backward-begin (&optional is-field-value)
  "Move to the last unmatched begin and return column of point.
If IS-FIELD-VALUE is non-nil, a between-pattern of the same nesting
level is also considered a begin-pattern.  This is used by indentation
to handle lines like 'attr a:'."
  (let ((ret nil)
        (nesting 0))
    (while (not ret)
      (if (oz-backward-keyword)
          (cond ((looking-at oz-declare-pattern)
                 (setq ret (current-column)))
                ((or (looking-at oz-class-begin-pattern)
                     (looking-at oz-class-member-pattern)
                     (looking-at oz-begin-pattern)
                     (looking-at oz-left-pattern)
                     (and is-field-value
                          (or (looking-at oz-class-between-pattern)
                              (and oz-gump-indentation
                                   (looking-at
                                    oz-gump-class-between-pattern))))
                     (and oz-gump-indentation
                          (or (looking-at oz-gump-class-begin-pattern)
                              (looking-at oz-gump-class-member-pattern))))
                 (if (= nesting 0)
                     (setq ret (current-column))
                   (setq nesting (1- nesting))))
                ((looking-at oz-end-pattern)
                 (setq nesting (1+ nesting)))
                ((looking-at oz-right-pattern)
                 (oz-backward-paren)))
        (goto-char (point-min))
        (if (= nesting 0)
            (setq ret 0)
          (error "No matching begin token"))))
    ret))

(defun oz-backward-paren ()
  "Move to the last unmatched opening parenthesis and return column of point."
  (let ((continue t)
        (nesting 0))
    (while continue
      (if (re-search-backward oz-left-or-right-pattern nil t)
          (cond ((oz-is-quoted) t)
                ((looking-at oz-left-pattern)
                 (if (= nesting 0)
                     (setq continue nil)
                   (setq nesting (1- nesting))))
                ((oz-is-box) t)
                (t
                 (setq nesting (1+ nesting))))
        (error "No matching opening parenthesis"))))
  (current-column))

(defun oz-forward-end ()
  "Move point to next unmatched end."
  (let ((continue t)
        (nesting 0))
    (while continue
      (if (oz-forward-keyword)
          (let ((cont-point (match-end 0)))
            (cond ((or (looking-at oz-class-begin-pattern)
                       (looking-at oz-class-member-pattern)
                       (looking-at oz-begin-pattern)
                       (and oz-gump-indentation
                            (or (looking-at oz-gump-class-begin-pattern)
                                (looking-at oz-gump-class-member-pattern))))
                   (setq nesting (1+ nesting))
                   (goto-char cont-point))
                  ((looking-at oz-end-pattern)
                   (cond ((= nesting 1)
                          (setq continue nil))
                         ((= nesting 0)
                          (error "Containing expression ends prematurely"))
                         (t
                          (setq nesting (1- nesting))
                          (goto-char cont-point))))
                  ((looking-at oz-left-pattern)
                   (forward-char)
                   (oz-forward-paren)
                   (forward-char))
                  ((looking-at oz-right-pattern)
                   (error "Containing expression ends prematurely"))
                  (t
                   (goto-char cont-point))))
        (setq continue nil)))))

(defun oz-forward-paren ()
  "Move to the next unmatched closing parenthesis."
  (let ((continue t)
        (nesting 0))
    (while continue
      (if (re-search-forward oz-left-or-right-pattern nil t)
          (progn
            (goto-char (match-beginning 0))
            (cond ((oz-is-quoted)
                   (goto-char (match-end 0)))
                  ((looking-at oz-right-pattern)
                   (if (= nesting 0)
                       (setq continue nil)
                     (setq nesting (1- nesting))
                     (forward-char)))
                  ((looking-at "\\[\\]")
                   (goto-char (match-end 0)))
                  (t
                   (forward-char)
                   (setq nesting (1+ nesting)))))
        (error "No matching closing parenthesis")))))

;;}}}
;;{{{ Indentation

(defun oz-electric-terminate-line ()
  "Terminate current line.
If variable `oz-auto-indent' is non-nil, indent the terminated line
and the following line."
  (interactive)
  (delete-horizontal-space) ; Removes trailing whitespace
  (open-line 1)
  (cond (oz-auto-indent (oz-indent-line-sub t)))
  (forward-line 1)
  (cond (oz-auto-indent (oz-indent-line-sub))))

(defun oz-indent-buffer ()
  "Indent every line in the current buffer."
  (interactive)
  (oz-indent-region (point-min) (point-max)))

(defun oz-indent-region (start end)
  "Indent every line in the current region."
  (interactive "r")
  (let ((old-line (count-lines 1 (point))))
    (goto-char start)
    (let ((current-line (+ (count-lines 1 start)
                           (if (= (current-column) 0) 1 0)))
          (end-line (1+ (count-lines 1 end))))
      (while (< current-line end-line)
        (message "Indenting line %s ..." current-line)
        (oz-indent-line-sub t)
        (setq current-line (1+ current-line))
        (forward-line 1)))
    (message nil)
    (goto-line old-line)))

(defun oz-indent-line (&optional arg)
  "Indent the current line.
If ARG is given, reindent that many lines above and below point as well."
  (interactive "P")
  (save-excursion
    (let* ((current-line (1+ (count-lines 1 (point))))
           (n (abs (if arg (prefix-numeric-value arg) 0)))
           (start-line (max (- current-line n) 1))
           (nlines (- current-line start-line)))
      (forward-line (- nlines))
      (while (> nlines 0)
        (oz-indent-line-sub t)
        (setq nlines (1- nlines))
        (forward-line 1))))
  (oz-indent-line-sub nil)
  (save-excursion
    (let ((nlines (abs (if arg (prefix-numeric-value arg) 0))))
      (while (> nlines 0)
        (if (= (forward-line 1) 0)
            (oz-indent-line-sub t))
        (setq nlines (1- nlines))))))

(defun oz-indent-line-sub (&optional dont-change-empty-lines)
  ;; Indent the current line.
  ;; If DONT-CHANGE-EMPTY-LINES is non-nil and the current line is empty
  ;; save for whitespace, then its indentation is not changed.  If the
  ;; point was inside the line's leading whitespace, then it is moved to
  ;; the end of this whitespace after indentation.
  (let ((case-fold-search nil))   ; respect case
    (unwind-protect
        (save-excursion
          (beginning-of-line)
          (skip-chars-forward " \t")
          (if (and dont-change-empty-lines (oz-is-empty)) t
            (let ((col (save-excursion (oz-calc-indent))))
              ;; a negative result means: do not change indentation
              (if (>= col 0)
                  (if (or (progn (beginning-of-line)
                                 (not (looking-at "\t* ? ? ? ? ? ? ?")))
                          (progn (goto-char (match-end 0))
                                 (or (looking-at "[\t ]")
                                     (/= (current-column) col))))
                      (progn
                        (delete-horizontal-space)
                        (indent-to col)))))))
      (if (oz-is-left)
          (skip-chars-forward " \t")))))

(defun oz-calc-indent ()
  ;; Calculate the required indentation for the current line.
  ;; The point must be at the beginning of the current line.
  ;; Return a negative value if the indentation is not to be changed,
  ;; else return the column up to where the line should be indented.
  (cond ((looking-at oz-declare-pattern)
         0)
        ((and (looking-at oz-directive-pattern)
              (not (looking-at oz-directives-to-indent)))
         ;; directive
         0)
        ((looking-at "%%%")
         0)
        ((looking-at "%[^%]")
         -1)
        ((oz-is-field-value)
         (+ (current-column) oz-indent-chars))
        ((oz-is-record-start)
         (+ (current-column) oz-indent-chars))
        ((or (looking-at oz-middle-pattern)
             (looking-at oz-end-pattern)
             (and oz-gump-indentation
                  (looking-at oz-gump-middle-pattern)))
         (oz-backward-begin))
        ((looking-at oz-right-pattern)
         (oz-backward-paren))
        (t
         (let ((ret nil)
               (is-class-member
                (or (looking-at oz-class-member-pattern)
                    (looking-at oz-class-between-pattern)
                    (and oz-gump-indentation
                         (or (looking-at oz-gump-class-member-pattern)
                             (looking-at oz-gump-class-between-pattern))))))
           (while (not ret)
             (if (oz-backward-keyword)
                 (cond ((looking-at oz-declare-pattern)
                        (setq ret (current-column)))
                       ((or (looking-at oz-class-begin-pattern)
                            (looking-at oz-class-member-pattern)
                            (looking-at oz-begin-pattern)
                            (and oz-gump-indentation
                                 (or (looking-at oz-gump-class-begin-pattern)
                                     (looking-at oz-gump-class-member-pattern)
                                     (looking-at oz-gump-between-pattern))))
                        (setq ret (+ (current-column) oz-indent-chars)))
                       ((or (looking-at oz-class-between-pattern)
                            (and oz-gump-indentation
                                 (looking-at oz-gump-class-between-pattern)))
                        (if is-class-member t
                          (setq ret (+ (current-column) oz-indent-chars))))
                       ((or (looking-at oz-middle-pattern)
                            (and oz-gump-indentation
                                 (looking-at oz-gump-middle-pattern)))
                        (oz-backward-begin)
                        (if (looking-at oz-declare-pattern)
                            ;; do not indent after 'declare X in'
                            (setq ret (current-column))
                          (setq ret (+ (current-column) oz-indent-chars))))
                       ((looking-at oz-end-pattern)
                        (oz-backward-begin)
                        (if (oz-is-left)
                            ;; this is an approximation made for efficiency
                            (setq ret (if (oz-is-field-value)
                                          (oz-calc-indent)
                                        (current-column)))))
                       ((looking-at oz-left-pattern)
                        (forward-char)
                        (setq ret (oz-get-column-of-next-nonwhite)))
                       ((looking-at oz-right-pattern)
                        (oz-backward-paren)))
               (setq ret 0)))
           ret))))

(defun oz-is-record-start ()
  ;; Return non-nil iff the token preceding the point is a record label.
  ;; This serves for the following indentation rule: in records with the
  ;; label at the end of the line, the subtrees should be indented relative
  ;; to the label.
  ;; If this is the case, move the point to the start of the label.
  (let ((old (point)))
    (if (and (progn
               (oz-backward-begin)
               (looking-at "([ \t]*$"))
             (not (oz-is-quoted))
             (/= (point) (point-min))
             (progn
               (backward-char)
               (looking-at oz-atom-or-variable-or-quote-pattern)))
        (or (oz-is-quoted)
            (skip-chars-backward oz-atom-or-variable-char)
            t)
      (goto-char old)
      nil)))

(defun oz-is-field-value ()
  ;; Return non-nil iff the token preceding the point is a colon.
  ;; This serves for the following indentation rule: in records with a feature
  ;; on one line and the corresponding subtree expression on another, the
  ;; subtree should be indented relative to the feature.
  ;; If this is the case, move the point to the beginning of the feature.
  (let ((old (point)))
    (if (and (progn
               (skip-chars-backward "? \n\t\r\v\f")
               (/= (point) (point-min)))
             (progn
               (backward-char)
               (looking-at ":"))
             (not (oz-is-quoted))
             (progn
               (skip-chars-backward "? \n\t\r\v\f")
               (/= (point) (point-min)))
             (progn
               (backward-char)
               (looking-at oz-atom-or-variable-or-quote-pattern)))
        (or (oz-is-quoted)
            (skip-chars-backward oz-atom-or-variable-char)
            t)
      (goto-char old)
      nil)))

(defun oz-get-column-of-next-nonwhite ()
  ;; Return the column number of the first non-white character to follow point.
  ;; If there is none until the end of line, return the column of point.
  (let ((col (current-column)))
    (if (oz-is-right)
        col
      (re-search-forward "[^ \t]" nil t)
      (1- (current-column)))))

(defun oz-is-left ()
  ;; Return non-nil iff the point is only preceded by whitespace in the line.
  (save-excursion
    (skip-chars-backward " \t")
    (= (current-column) 0)))

(defun oz-is-right ()
  ;; Return non-nil iff the point is only followed by whitespace in the line.
  (looking-at "[ \t]*$"))

(defun oz-is-empty ()
  ;; Return non-nil iff the current line is empty save for whitespace.
  (and (oz-is-left) (oz-is-right)))

;;}}}
;;{{{ Oz Expression Hopping

(defun forward-oz-expr (&optional arg)
  "Move forward one balanced Oz expression.
With argument, do it that many times.  Negative ARG means backwards."
  (interactive "p")
  (let ((case-fold-search nil))
    (or arg (setq arg 1))
    (if (< arg 0)
        (backward-oz-expr (- arg))
      (while (> arg 0)
        (if (oz-is-quoted)
            (progn (goto-char (match-end 0)) (setq arg (1- arg)))
          (let ((pos (scan-sexps (point) 1)))
            (if (not pos)
                (progn (goto-char (point-max)) (setq arg 0))
              (goto-char pos)
              (if (= (char-syntax (preceding-char)) ?w)
                  (progn
                    (forward-word -1)
                    (cond ((or (looking-at oz-class-begin-pattern)
                               (looking-at oz-class-member-pattern)
                               (looking-at oz-begin-pattern)
                               (and oz-gump-indentation
                                    (or (looking-at
                                         oz-gump-class-begin-pattern)
                                        (looking-at
                                         oz-gump-class-member-pattern))))
                           (oz-forward-end)
                           (goto-char (match-end 0)))
                          ((or (looking-at oz-class-between-pattern)
                               (looking-at oz-middle-pattern)
                               (and oz-gump-indentation
                                    (or (looking-at
                                         oz-gump-class-between-pattern)
                                        (looking-at
                                         oz-gump-between-pattern)
                                        (looking-at
                                         oz-gump-middle-pattern))))
                           (goto-char (match-end 0))
                           (setq arg (1+ arg)))
                          ((looking-at oz-end-pattern)
                           (error "Containing expression ends prematurely"))
                          (t
                           (forward-word 1)))))
              (setq arg (1- arg)))))))))

(defun backward-oz-expr (&optional arg)
  "Move backward one balanced Oz expression.
With argument, do it that many times.  Argument must be positive."
  (interactive "p")
  (let ((case-fold-search nil))
    (or arg (setq arg 1))
    (while (> arg 0)
      (let ((pos (scan-sexps (point) -1)))
        (if (equal pos nil)
            (progn (beginning-of-buffer) (setq arg 0))
          (goto-char pos)
          (cond ((looking-at oz-end-pattern)
                 (oz-backward-begin))
                ((or (looking-at oz-class-between-pattern)
                     (looking-at oz-middle-pattern)
                     (and oz-gump-indentation
                          (or (looking-at oz-gump-class-between-pattern)
                              (looking-at oz-gump-between-pattern)
                              (looking-at oz-gump-middle-pattern))))
                 (setq arg (1+ arg)))
                ((looking-at oz-begin-pattern)
                 (error "Containing expression ends prematurely")))
          (setq arg (1- arg)))))))

(defun mark-oz-expr (arg)
  "Set mark ARG balanced Oz expressions from point.
The place mark goes to is the same place \\[forward-oz-expr] would
move to with the same argument."
  (interactive "p")
  (push-mark
    (save-excursion
      (forward-oz-expr arg)
      (point))
    nil t))

(defun transpose-oz-exprs (arg)
  "Like \\[transpose-words] but applies to balanced Oz expressions.
Does not work in all cases."
  (interactive "*p")
  (transpose-subr 'forward-oz-expr arg))

(defun kill-oz-expr (arg)
  "Kill the balanced Oz expression following point.
With argument, kill that many Oz expressions after point.
Negative arg -N means kill N Oz expressions before point."
  (interactive "p")
  (let ((pos (point)))
    (forward-oz-expr arg)
    (kill-region pos (point))))

(defun backward-kill-oz-expr (arg)
  "Kill the balanced Oz expression preceding point.
With argument, kill that many Oz expressions before point.
Negative arg -N means kill N Oz expressions after point."
  (interactive "p")
  (let ((pos (point)))
    (forward-oz-expr (- arg))
    (kill-region pos (point))))

(defun indent-oz-expr (&optional endpos)
  "Indent each line of the balanced Oz expression starting just after point.
If optional arg ENDPOS is given, indent each line, stopping when ENDPOS is
encountered."
  (interactive "P")
  (save-excursion
    (let ((pos (point)))
      (forward-oz-expr)
      (oz-indent-region pos (if endpos (min (point) endpos) (point))))))

(defconst oz-defun-pattern
  (oz-make-keywords-for-match '("proc" "fun" "class" "meth")))

(defun oz-beginning-of-defun ()
  "Move to the start of the proc/fun/class/meth definition point is in.
If point is not inside a proc/fun/class definition, move to start of buffer.
Returns t unless search stops due to beginning or end of buffer."
  (interactive)
  (let ((continue t) ret)
    (while continue
      (oz-backward-begin)
      (cond ((looking-at oz-defun-pattern)
             (setq continue nil ret t))
            ((= (point) (point-min))
             (setq continue nil ret nil))))
    ret))

(defun oz-end-of-defun ()
  "Move to the end of the proc/fun/class/meth definition point is in.
If point is not inside a proc/fun/class/meth definition, move to end of
buffer."
  (interactive)
  (cond ((oz-beginning-of-defun)
         (oz-forward-end)
         (goto-char (match-end 0)))
        (t
         (goto-char (point-max)))))

;;}}}
;;{{{ Keymap Definitions

;; Silence the compiler warnings below
(defvar is-alias)
(defvar map)

(defun oz-define-key (key fun)
  ;; if IS-ALIAS is non nil, define fun/tty to be an alias for fun
  ;; and use fun/tty as the definition instead of fun.  This way
  ;; menu entries will always document the short prefix.
  (let ((afun fun))
    (cond (is-alias
           (setq afun (intern (concat (symbol-name fun) "/tty")))
           (fset afun fun)))
    (define-key map key afun)))

(defun oz-define-prefixed-keys (map prefix &optional is-alias)
  (oz-define-key `[,@prefix ?e] 'oz-toggle-emulator)
  (oz-define-key `[,@prefix ?c] 'oz-toggle-compiler)
  (oz-define-key `[,@prefix ?t] 'oz-toggle-temp)
  (oz-define-key `[,@prefix ?r] 'run-oz)
  (oz-define-key `[,@prefix ?h] 'oz-halt)
  (oz-define-key `[,@prefix ?n] 'oz-new-buffer)
  ;;
  (oz-define-key `[,@prefix (control ?b)] 'oz-feed-buffer)
  (oz-define-key `[,@prefix (control ?r)] 'oz-feed-region)
  (oz-define-key `[,@prefix (control ?l)] 'oz-feed-line)
  (oz-define-key `[,@prefix (control ?p)] 'oz-feed-paragraph)
  ;;
  (oz-define-key `[,@prefix ?s (control ?b)] 'oz-show-buffer)
  (oz-define-key `[,@prefix ?s (control ?r)] 'oz-show-region)
  (oz-define-key `[,@prefix ?s (control ?l)] 'oz-show-line)
  (oz-define-key `[,@prefix ?s (control ?p)] 'oz-show-paragraph)
  ;;
  (oz-define-key `[,@prefix ?b (control ?b)] 'oz-browse-buffer)
  (oz-define-key `[,@prefix ?b (control ?r)] 'oz-browse-region)
  (oz-define-key `[,@prefix ?b (control ?l)] 'oz-browse-line)
  (oz-define-key `[,@prefix ?b (control ?p)] 'oz-browse-paragraph)
  ;;
  (oz-define-key `[,@prefix ?i (control ?b)] 'oz-inspect-buffer)
  (oz-define-key `[,@prefix ?i (control ?r)] 'oz-inspect-region)
  (oz-define-key `[,@prefix ?i (control ?l)] 'oz-inspect-line)
  (oz-define-key `[,@prefix ?i (control ?p)] 'oz-inspect-paragraph)
  ;;
  (oz-define-key `[,@prefix ,@prefix ?s] 'oz-open-panel)
  (oz-define-key `[,@prefix ,@prefix ?n] 'oz-open-distribution-panel)
  (oz-define-key `[,@prefix ,@prefix ?c] 'oz-open-compiler-panel)
  (oz-define-key `[,@prefix ,@prefix ?p] 'oz-profiler)
  (oz-define-key `[,@prefix ,@prefix ?d] 'oz-debugger))

(defvar oz-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [tab]    'oz-indent-line)
    (define-key map [del]    'backward-delete-char-untabify)
    (define-key map [return] 'oz-electric-terminate-line)
    ;;
    (define-key map [(control ?x) ? ]    'oz-breakpoint-at-point)
    (define-key map [(meta control ?x)]  'oz-feed-paragraph)
    (define-key map [(meta control ?f)]  'forward-oz-expr)
    (define-key map [(meta control ?b)]  'backward-oz-expr)
    (define-key map [(meta control ?k)]  'kill-oz-expr)
    (define-key map [(meta control ?\@)] 'mark-oz-expr)
    (define-key map [(meta control ? )]  'mark-oz-expr)
    (define-key map [(meta control del)] 'backward-kill-oz-expr)
    (define-key map [(meta control ?q)]  'indent-oz-expr)
    (define-key map [(meta control ?a)]  'oz-beginning-of-defun)
    (define-key map [(meta control ?e)]  'oz-end-of-defun)
    (define-key map [(meta control ?t)]  'transpose-oz-exprs)
    ;;
    (define-key map [(meta ?n)] 'oz-next-buffer)
    (define-key map [(meta ?p)] 'oz-previous-buffer)
    ;;
    (oz-define-prefixed-keys map [(control ?.)])
    ;; use aliases for the long prefix
    (oz-define-prefixed-keys map [(control ?c) ?.] t)
    map)
  "Keymap used in the Oz modes.")

;;}}}
;;{{{ Menus

;; GNU Emacs: a menubar is a usual key sequence with prefix "menu-bar"
;; Lucid Emacs: a menubar is a new datastructure
;;    (see function set-buffer-menubar)

(defvar oz-menubar nil
  "Oz Menubar for Lucid Emacs.")

(defun oz-make-menu (list)
  (cond (oz-gnu-emacs
         (oz-make-menu-gnu oz-mode-map
                           (list (cons "menu-bar" (cons nil list))))
         ;;(define-key oz-mode-map [down-mouse-3] 'oz-menubar)
         )
        (oz-lucid-emacs
         (setq oz-menubar (car (oz-make-menu-lucid list))))))

(defvar oz-temp-counter 0
  "Internal counter for gensym.")

(defun oz-make-temp-name (prefix)
  (setq oz-temp-counter (1+ oz-temp-counter))
  (intern (format "%s%d" (make-temp-name prefix) oz-temp-counter)))

(defun oz-make-menu-gnu (map list)
  (if list
      (progn
        (let* ((entry (car list))
               (name (car entry))
               (aname (intern name))
               (command (car (cdr entry)))
               (rest (cdr (cdr entry))))
          (cond ((null rest)
                 (define-key map (vector (oz-make-temp-name name))
                   (cons name nil)))
                ((null command)
                 (let ((newmap (make-sparse-keymap name)))
                   (define-key map (vector aname)
                     (cons name newmap))
                   (if (string= name "Oz")
                       (fset 'oz-menubar newmap))
                   (oz-make-menu-gnu newmap (reverse rest))))
                (t
                 (define-key map (vector aname) (cons name command))
                 (put command 'menu-enable (car rest)))))
        (oz-make-menu-gnu map (cdr list)))))

(defun oz-make-menu-lucid (list)
  (if list
      (cons
       (let* ((entry (car list))
              (name (car entry))
              (command (car (cdr entry)))
              (rest (cdr (cdr entry))))
         (cond ((null rest)
                (vector name nil nil))
               ((null command)
                (cons name (oz-make-menu-lucid rest)))
               (t
                (vector name command (car rest)))))
       (oz-make-menu-lucid (cdr list)))))

(defvar oz-menu
 '(("Oz" nil
    ("Indent" nil
     ("Buffer"             oz-indent-buffer t)
     ("Region"             oz-indent-region (mark t))
     ("Line"               oz-indent-line t))
    ("Comment" nil
     ("Comment Region"     oz-comment-region (mark t))
     ("Uncomment Region"   oz-uncomment-region (mark t)))
    ("Print" nil
     ("Buffer"             ps-print-buffer-with-faces t)
     ("Region"             ps-print-region-with-faces (mark t)))
    ("-----")
    ("Next Oz Buffer"      oz-next-buffer t)
    ("Previous Oz Buffer"  oz-previous-buffer t)
    ("New Oz Buffer"       oz-new-buffer t)
    ("-----")
    ("Feed Buffer"         oz-feed-buffer t)
    ("Feed Region"         oz-feed-region (mark t))
    ("Feed Line"           oz-feed-line t)
    ("Feed Paragraph"      oz-feed-paragraph t)
    ("Feed File"           oz-feed-file t)
    ("Compile File"        oz-compile-file (buffer-file-name))
    ("-----")
    ("Core Syntax" nil
     ("Buffer"             oz-to-coresyntax-buffer t)
     ("Region"             oz-to-coresyntax-region (mark t))
     ("Line"               oz-to-coresyntax-line t)
     ("Paragraph"          oz-to-coresyntax-paragraph t))
    ("Emulator Code" nil
     ("Buffer"             oz-to-emulatorcode-buffer t)
     ("Region"             oz-to-emulatorcode-region (mark t))
     ("Line"               oz-to-emulatorcode-line t)
     ("Paragraph"          oz-to-emulatorcode-paragraph t))
    ("Browse" nil
     ("Buffer"             oz-browse-buffer t)
     ("Region"             oz-browse-region (mark t))
     ("Line"               oz-browse-line t)
     ("Paragraph"          oz-browse-paragraph t))
     ("Inspect" nil
      ("Buffer"             oz-inspect-buffer t)
      ("Region"             oz-inspect-region (mark t))
      ("Line"               oz-inspect-line t)
      ("Paragraph"          oz-inspect-paragraph t))
    ("Open Panel"          oz-open-panel t)
    ("Open Compiler Panel" oz-open-compiler-panel t)
    ("Open Distribution Panel" oz-open-distribution-panel t)
    ("Start Debugger"      oz-debugger t)
    ("Debug Application"   oz-debug-application (not (oz-is-running)))
    ("Start Profiler"      oz-profiler t)
    ("-----")
    ("Show/Hide" nil
     ("Compiler"           oz-toggle-compiler (get-buffer oz-compiler-buffer))
     ("Emulator"           oz-toggle-emulator (get-buffer oz-emulator-buffer))
     ("Temporary Buffer"   oz-toggle-temp (get-buffer oz-temp-buffer)))
    ("-----")
    ("Run Oz"              run-oz t)
    ("Halt Oz"             oz-halt t)))
  "Contents of the Oz menu.")

(oz-make-menu oz-menu)

;;}}}
;;{{{ Syntax Table Definitions

(defvar oz-mode-syntax-table
  (make-syntax-table)
  "Syntax table used in the Oz modes.")

(modify-syntax-entry ?_ "w" oz-mode-syntax-table)
(modify-syntax-entry ?\\ "/" oz-mode-syntax-table)
(modify-syntax-entry ?+ "." oz-mode-syntax-table)
(modify-syntax-entry ?- "." oz-mode-syntax-table)
(modify-syntax-entry ?= "." oz-mode-syntax-table)
(modify-syntax-entry ?< "." oz-mode-syntax-table)
(modify-syntax-entry ?> "." oz-mode-syntax-table)
(modify-syntax-entry ?\" "\"" oz-mode-syntax-table)
(modify-syntax-entry ?\' "\"" oz-mode-syntax-table)
(modify-syntax-entry ?\` "\"" oz-mode-syntax-table)
(modify-syntax-entry ?%  "<" oz-mode-syntax-table)
(modify-syntax-entry ?\n ">" oz-mode-syntax-table)
(modify-syntax-entry ?/ ". 14" oz-mode-syntax-table)
(modify-syntax-entry ?* ". 23b" oz-mode-syntax-table)
(modify-syntax-entry ?. "_" oz-mode-syntax-table)

;; add the accented characters:
(defun oz-modify-syntax-entries (start end s)
  (let ((i start))
    (while (<= i end)
      (modify-syntax-entry i s oz-mode-syntax-table)
      (setq i (1+ i)))))
(oz-modify-syntax-entries 192 214 "w")
(oz-modify-syntax-entries 216 222 "w")
(oz-modify-syntax-entries 223 246 "w")
(oz-modify-syntax-entries 248 255 "w")

;;}}}
;;{{{ Major Mode Definitions

(defun oz-mode-variables ()
  (set (make-local-variable 'paragraph-start)
       "\f\\|$")
  (set (make-local-variable 'paragraph-separate)
       paragraph-start)
  (set (make-local-variable 'paragraph-ignore-fill-prefix)
       t)
  (set (make-local-variable 'fill-paragraph-function)
       'oz-fill-paragraph)
  (set (make-local-variable 'indent-line-function)
       'oz-indent-line)
  (set (make-local-variable 'comment-start)
       "%")
  (set (make-local-variable 'comment-end)
       "")
  (set (make-local-variable 'comment-start-skip)
       "/\\*+ *\\|%+ *")
  (set (make-local-variable 'parse-sexp-ignore-comments)
       t)
  (set (make-local-variable 'words-include-escapes)
       t))

(defun oz-mode ()
  "Major mode for editing Oz code.

Commands:
\\{oz-mode-map}
Entry to this mode calls the value of `oz-mode-hook'
if that value is non-nil."
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'oz-mode)
  (setq mode-name "Oz")
  (use-local-map oz-mode-map)
  (set-syntax-table oz-mode-syntax-table)
  (oz-mode-variables)
  (set (make-local-variable 'oz-gump-indentation) nil)
  (oz-set-lucid-menu)
  (oz-set-font-lock-defaults)
  (if (and oz-want-font-lock window-system)
      (font-lock-mode 1))
  (run-hooks 'oz-mode-hook))

(defun oz-gump-mode ()
  "Major mode for editing Oz code with embedded Gump specifications.

Commands:
\\{oz-mode-map}
Entry to this mode calls the value of `oz-mode-hook'
if that value is non-nil."
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'oz-gump-mode)
  (setq mode-name "Oz-Gump")
  (use-local-map oz-mode-map)
  (set-syntax-table oz-mode-syntax-table)
  (oz-mode-variables)
  (set (make-local-variable 'oz-gump-indentation) t)
  (oz-set-lucid-menu)
  (oz-gump-set-font-lock-defaults)
  (if (and oz-want-font-lock window-system)
      (font-lock-mode 1))
  (run-hooks 'oz-mode-hook))

;; Silence the compiler warnings below
(defvar mode-popup-menu)
(defvar current-menubar)

(defun oz-set-lucid-menu ()
  ;; Add the Oz menu to the menu bar.
  (if oz-lucid-emacs
      (progn
        (setq mode-popup-menu (cons "Oz Mode Menu" (cdr oz-menubar)))
        (if (and (featurep 'menubar) current-menubar)
            (progn
              (set-buffer-menubar current-menubar)
              (add-submenu nil oz-menubar))))))

;;}}}
;;{{{ Lisp Paragraph Filling Commands

(defun oz-fill-paragraph (&optional justify)
  "Like \\[fill-paragraph], but handles Oz comments.
If any of the current line is a comment, fill the comment or the
paragraph of it that point is in, preserving the comment's indentation
and initial percent signs."
  (interactive "P")
  (let (
        ;; Non-nil if the current line contains a comment.
        has-comment

        ;; If has-comment, the appropriate fill-prefix for the comment.
        comment-fill-prefix
        )

    ;; Figure out what kind of comment we are looking at.
    (save-excursion
      (beginning-of-line)
      (cond

       ;; A line with nothing but a comment on it?
       ((looking-at "[ \t]*%[% \t]*")
        (setq has-comment t
              comment-fill-prefix (buffer-substring (match-beginning 0)
                                                    (match-end 0))))

       ;; A line with some code, followed by a comment?  Remember that the
       ;; percent sign which starts the comment shouldn't be part of a string
       ;; or character.
       ((progn
          (while (not (looking-at "%\\|$"))
            (skip-chars-forward "^%\n\\\\")
            (cond
             ((eq (char-after (point)) ?\\) (forward-char 2))))
          (looking-at "%+[ \t]*"))
        (setq has-comment t)
        (setq comment-fill-prefix
              (concat (make-string (current-column) ? )
                      (buffer-substring (match-beginning 0) (match-end 0)))))))

    (if (not has-comment)
        (fill-paragraph justify)

      ;; Narrow to include only the comment, and then fill the region.
      (save-restriction
        (narrow-to-region
         ;; Find the first line we should include in the region to fill.
         (save-excursion
           (while (and (zerop (forward-line -1))
                       (looking-at "^[ \t]*%")))
           ;; We may have gone to far.  Go forward again.
           (or (looking-at "^[ \t]*%")
               (forward-line 1))
           (point))
         ;; Find the beginning of the first line past the region to fill.
         (save-excursion
           (while (progn (forward-line 1)
                         (looking-at "^[ \t]*%")))
           (point)))

        ;; Lines with only percent signs on them can be paragraph boundaries.
        (let ((paragraph-start (concat paragraph-start "\\|^[ \t%]*$"))
              (paragraph-separate (concat paragraph-start "\\|^[ \t%]*$"))
              (fill-prefix comment-fill-prefix))
          (fill-paragraph justify))))
    t))

;;}}}
;;{{{ Fontification

(if window-system
    (require 'font-lock))

(defconst oz-keywords
  '("declare" "local" "in" "end"
    "proc" "fun"
    "functor" "require" "prepare" "import" "export" "define" "at"
    "case" "then" "else" "of" "elseof" "elsecase"
    "if" "elseif"
    "class" "from" "prop" "attr" "feat" "meth" "self"
    "true" "false" "unit"
    "div" "mod" "andthen" "orelse"
    "cond" "or" "dis" "choice" "not"
    "thread" "try" "catch" "finally" "raise" "lock"
    "skip" "fail" "for" "do")
  "List of all Oz keywords with identifier syntax.")

(defconst oz-char-matcher
  (concat "&\\(" "[^\C-@\\\n]" "\\|" "\\\\" "\\("
          "[0-7][0-7][0-7]\\|x[0-9A-Fa-f][0-9A-Fa-f]\\|[abfnrtv\\'\"`]"
          "\\)" "\\)")
  "Regular expression matching an ampersand character constant.
Used only for fontification.")

(defconst oz-directive-matcher
  "\\(^\\|[^&]\\)\\(\\\\[a-z]\\([^\'%\n]\\|'[\"-~]'\\)*\\)"
  "Regular expression matching a compiler or macro directive.
Used only for fontification.")

(defconst oz-keywords-matcher-1
  (concat "^\\(" (mapconcat 'identity oz-keywords "\\|") "\\)\\>")
  "Regular expression matching any keyword at the beginning of a line.")

(defconst oz-keywords-matcher-2
  (concat "[^\\" oz-atom-or-variable-char "]\\("
          (mapconcat 'identity oz-keywords "\\|") "\\)\\>")
  "Regular expression matching any keyword not preceded by a backslash.
This serves to distinguish between the directive `\\else' and the keyword
`else'.  Keywords at the beginning of a line are not matched.
The first subexpression matches the keyword proper (for fontification).")

(defconst oz-keywords-matcher-3
  "[\253\273!#|.@,~*/+-]\\|\\[\\]\\|:::?\\|=?<[=:]?\\|>=?:?\\|=:\\|\\\\=:?\\|==\\|>>\\|<<\\|:="
  "Regular expression matching non-identifier keywords and operators.")

(defconst oz-proc-fun-matcher
  (concat "\\<\\(proc\\|fun\\)\\>\\([^{\n]*\\){!?"
          "\\([A-Z\300-\326\330-\336]"
          "[" oz-atom-or-variable-char ".]*\\|\\$"
          "\\|`[^`\n]*`\\|\\)")
  "Regular expression matching proc or fun definitions.
The second subexpression matches optional flags, the third subexpression
matches the definition's identifier (if it is a variable) and is used for
fontification.")

(defconst oz-for-matcher
  "\\<\\(for\\)\\s +\\(lazy\\)\\>"
  "Regular expression matching a for keyword followed by a lazy flag")

(defconst oz-functor-matcher
  (concat "\\<functor\\([ \t]+\\|[ \t]*!\\)"
          "\\([A-Z\300-\326\330-\336]"
          "[" oz-atom-or-variable-char ".]*\\|\\$"
          "\\|`[^`\n]*`\\)")
  "Regular expression matching functor definitions.
The second subexpression matches the definition's identifier (if it is a
variable) and is used for fontification.")

(defconst oz-class-matcher
  (concat "\\<class\\([ \t]+\\|[ \t]*!\\)"
          "\\([A-Z\300-\326\330-\336]"
          "[" oz-atom-or-variable-char ".]*\\|\\$"
          "\\|`[^`\n]*`\\)")
  "Regular expression matching class definitions.
The second subexpression matches the definition's identifier
\(if it is a variable) and is used for fontification.")

(defconst oz-from-matcher
  (concat "\\<from\\(\\([ \t]+"
          "\\([A-Z\300-\326\330-\336]"
          "[" oz-atom-or-variable-char ".]*\\|\\$"
          "\\|`[^`\n]*`\\)\\)+\\)")
  "Regular expression matching class parents.
The first subexpression matches the parents' identifiers
\(if they are variables) and is used for fontification.")

(defconst oz-meth-matcher
  (concat "\\<meth\\([ \t]+\\|[ \t]*!\\)"
          "\\([A-Z\300-\326\330-\336a-z\337-\366\370-\377]"
          "[" oz-atom-or-variable-char "_]*\\|"
          "`[^`\n]*`\\|'[^'\n]*'\\)")
  "Regular expression matching method definitions.
The second subexpression matches the definition's identifier
and is used for fontification.")

(defconst oz-space-matcher-1
  "[ \t]+$"
  "Regular expression matching space at the end of a line.")

(defconst oz-space-matcher-2
  "\\( +\\)\t"
  "Regular expression matching spaces before a TAB character.")

(defconst oz-space-matcher-3
  "[^\t\n ].*\\(\t+\\)"
  "Regular expression matching TAB characters in the middle of a line.")

(defconst oz-space-matcher-4
  "^\\(        \\)+"
  "Regular expression matching \"expanded\" TAB characters at BOL.")

(defconst oz-space-matcher-5
  "\t\\(\\(        \\)+\\)"
  "Regular expression matching \"expanded\" TAB characters after TABs.")

(defconst oz-font-lock-keywords-1
  (list (cons oz-char-matcher 'font-lock-string-face)
        oz-keywords-matcher-1
        (cons oz-keywords-matcher-2 1)
        oz-keywords-matcher-3)
  "Subdued level highlighting for Oz mode.")

(defconst oz-font-lock-keywords oz-font-lock-keywords-1
  "Default expressions to highlight in Oz mode.")

(defconst oz-font-lock-keywords-2
  (cons (list oz-directive-matcher
              '(2 font-lock-reference-face))
        oz-font-lock-keywords-1)
  "Medium level highlighting for Oz mode.")

(defconst oz-font-lock-keywords-3
  (append (list (list oz-proc-fun-matcher
                      '(2 font-lock-variable-name-face)
                      '(3 font-lock-function-name-face))
                (list oz-for-matcher
                      '(2 font-lock-variable-name-face))
                (list oz-functor-matcher
                      '(2 font-lock-function-name-face))
                (list oz-class-matcher
                      '(2 font-lock-type-face))
                (list oz-from-matcher
                      '(1 font-lock-type-face))
                (list oz-meth-matcher
                      '(2 font-lock-function-name-face))
                (cons oz-space-matcher-1
                      '(0 (cond (oz-pedantic-spaces oz-space-face))))
                (list oz-space-matcher-2
                      '(1 (cond (oz-pedantic-spaces oz-space-face))))
                (list oz-space-matcher-3
                      '(1 (cond (oz-pedantic-spaces oz-space-face))))
                (cons oz-space-matcher-4
                      '(0 (cond (oz-pedantic-spaces oz-space-face))))
                (list oz-space-matcher-5
                      '(1 (cond (oz-pedantic-spaces oz-space-face)))))
          oz-font-lock-keywords-2)
  "Gaudy level highlighting for Oz mode.")

(defun oz-set-font-lock-defaults ()
  (set (make-local-variable 'font-lock-defaults)
       '((oz-font-lock-keywords
          oz-font-lock-keywords-1
          oz-font-lock-keywords-2
          oz-font-lock-keywords-3)
         nil nil ((?& . "/")) beginning-of-line)))

;;{{{ Fontification for Oz-Gump Mode

(defconst oz-gump-keywords
  '("lex" "mode" "parser" "prod" "scanner" "syn" "token"))

(defconst oz-gump-keywords-matcher-1
  (concat "^\\(" (mapconcat 'identity oz-gump-keywords "\\|") "\\)\\>")
  "Regular expression matching any keyword at the beginning of a line.")

(defconst oz-gump-keywords-matcher-2
  (concat "[^\\" oz-atom-or-variable-char "]\\("
          (mapconcat 'identity oz-gump-keywords "\\|") "\\)\\>")
  "Regular expression matching any keyword not preceded by a backslash.
This serves to distinguish between the directive `\\else' and the keyword
`else'.  Keywords at the beginning of a line are not matched.
The first subexpression matches the keyword proper (for fontification).")

(defconst oz-gump-keywords-matcher-3
  "=>\\|//"
  "Regular expression matching non-identifier keywords.")

(defconst oz-gump-scanner-parser-matcher
  (concat "\\<\\(parser\\|scanner\\)[ \t]+"
          "\\([A-Z\300-\326\330-\336]"
          "[" oz-atom-or-variable-char "]*\\|`[^`\n]*`\\)")
  "Regular expression matching parser or scanner definitions.
The second subexpression matches the definition's identifier
\(if it is a variable) and is used for fontification.")

(defconst oz-gump-lex-matcher
  (concat "\\<lex[ \t]+"
          "\\([a-z\337-\366\370-\377]"
          "[" oz-atom-or-variable-char "]*\\|"
          "'[^'\n]*'\\)[ \t]*=")
  "Regular expression matching lexical abbreviation definitions.
The first subexpression matches the definition's identifier
\(if it is an atom) and is used for fontification.")

(defconst oz-gump-syn-matcher
  (concat "\\<syn[ \t]+"
          "\\([A-Z\300-\326\330-\336a-z\337-\366\370-\377]"
          "[" oz-atom-or-variable-char "]*\\|"
          "`[^`\n]*`\\|'[^'\n]*'\\)")
  "Regular expression matching syntax rule definitions.
The first subexpression matches the definition's identifier
and is used for fontification.")

(defconst oz-gump-font-lock-keywords-1
  (append (list (list oz-gump-regex-matcher
                      '(1 font-lock-string-face))
                oz-gump-keywords-matcher-1
                (cons oz-gump-keywords-matcher-2 1)
                oz-gump-keywords-matcher-3)
          oz-font-lock-keywords-1)
  "Subdued level highlighting for Oz-Gump mode.")

(defconst oz-gump-font-lock-keywords oz-gump-font-lock-keywords-1
  "Default expressions to highlight in Oz-Gump mode.")

(defconst oz-gump-font-lock-keywords-2
  (append (list (list oz-gump-regex-matcher
                      '(1 font-lock-string-face))
                oz-gump-keywords-matcher-1
                (cons oz-gump-keywords-matcher-2 1)
                oz-gump-keywords-matcher-3)
          oz-font-lock-keywords-2)
  "Medium level highlighting for Oz-Gump mode.")

(defconst oz-gump-font-lock-keywords-3
  (append (list (list oz-gump-regex-matcher
                      '(1 font-lock-string-face))
                oz-gump-keywords-matcher-1
                (cons oz-gump-keywords-matcher-2 1)
                oz-gump-keywords-matcher-3
                (list oz-gump-scanner-parser-matcher
                      '(2 font-lock-type-face))
                (list oz-gump-lex-matcher
                      '(1 font-lock-type-face))
                (list oz-gump-syn-matcher
                      '(1 font-lock-function-name-face)))
          oz-font-lock-keywords-3)
  "Gaudy level highlighting for Oz-Gump mode.")

(defun oz-gump-set-font-lock-defaults ()
  (set (make-local-variable 'font-lock-defaults)
       '((oz-gump-font-lock-keywords oz-gump-font-lock-keywords-1
          oz-gump-font-lock-keywords-2 oz-gump-font-lock-keywords-3)
         nil nil ((?& . "/")) beginning-of-line)))

;;}}}
;;}}}
;;{{{ Buffers

(defun oz-new-buffer ()
  "Create a new buffer and edit it in Oz mode."
  (interactive)
  (switch-to-buffer (generate-new-buffer "Oz"))
  (oz-mode))

(defun oz-previous-buffer ()
  "Switch to the next buffer in the buffer list that runs in an Oz mode."
  (interactive)
  (bury-buffer)
  (oz-walk-through-buffers (buffer-list)))

(defun oz-next-buffer ()
  "Switch to the last buffer in the buffer list that runs in an Oz mode."
  (interactive)
  (oz-walk-through-buffers (reverse (buffer-list))))

(defun oz-walk-through-buffers (buffers)
  (let ((none-found t) (cur (current-buffer)))
    (while (and buffers none-found)
      (set-buffer (car buffers))
      (if (or (equal mode-name "Oz")
              (equal mode-name "Oz-Gump")
              (equal mode-name "Oz-Machine"))
          (progn
            (switch-to-buffer (car buffers))
            (setq none-found nil))
        (setq buffers (cdr buffers))))
    (if none-found
        (progn
          (set-buffer cur)
          (error "There is no buffer in an Oz mode")))))

;;}}}
;;{{{ Misc Goodies

(defun oz-remove-annoying-spaces ()
  "Remove all ill-placed whitespace from the current buffer.
This is all the whitespace that is highlighted in oz-space-face when
the variable `oz-pedantic-spaces' is non-nil."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((current-line (1+ (count-lines 1 (point)))))
      (while (< (point) (point-max))
        (message "Removing annoying spaces from line %s ..." current-line)
        (if (looking-at "\t* ? ? ? ? ? ? ?\\($\\|[^ \t]\\)")
            (goto-char (match-end 0))
          (skip-chars-forward " \t")
          (let ((col (current-column)))
            (delete-horizontal-space)
            (indent-to col)))
        (while (progn (skip-chars-forward "^\t\n")
                      (looking-at "\t"))
          (let ((col1 (save-excursion
                        (goto-char (match-beginning 0))
                        (current-column)))
                (col2 (save-excursion
                        (goto-char (match-end 0))
                        (current-column))))
            (replace-match "" nil t)
            (insert-char ?  (- col2 col1))))
        (end-of-line)
        (skip-chars-backward " \t")
        (if (not (oz-is-quoted))
            (delete-horizontal-space))
        (forward-line)
        (setq current-line (1+ current-line)))
      (message nil))))

(defun oz-comment-region (start end &optional arg)
  "Comment or uncomment each line in the region.
With just \\[universal-argument] prefix arg, uncomment each line in region.
Numeric prefix arg ARG means use ARG comment characters.
If ARG is negative, delete that many comment characters instead.
Blank lines do not get comments."
  (interactive "r\np")
  (comment-region start end arg))

(defun oz-uncomment-region (start end &optional arg)
  "Comment or uncomment each line in the region.
See \\[oz-comment-region] for more information; note that the
prefix ARG is negated."
  (interactive "r\np")
  (comment-region start end (if (and arg (/= arg 0)) (- arg) -1)))

;;}}}


(provide 'oz)

;;; Local Variables: ***
;;; mode: emacs-lisp ***
;;; byte-compile-dynamic-docstrings: nil ***
;;; byte-compile-compatibility: t ***
;;; End: ***
