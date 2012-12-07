(require 'outline)

(defvar oz-outline-mode nil)
(make-variable-buffer-local 'oz-outline-mode)

(defun oz-outline-mode (&optional arg)
  (interactive "P")
  (setq oz-outline-mode
        (if (null arg) (not oz-outline-mode)
          (> (prefix-numeric-value arg) 0)))
  (if (and oz-outline-mode
           (eq major-mode 'outline-mode))
      (hide-other)))

(setq minor-mode-alist
      (cons '(oz-outline-mode " Click") minor-mode-alist))

(defvar oz-outline-map (make-sparse-keymap))
(define-key oz-outline-map [mouse-2] 'oz-outline-toggle-subtree)
(define-key oz-outline-map [mouse-3] 'oz-outline-reveal-headings)

(setq minor-mode-map-alist
      (cons (cons 'oz-outline-mode oz-outline-map)
            minor-mode-map-alist))

(defun oz-outline-toggle-subtree (e)
  (interactive "e")
  (mouse-set-point e)
  (save-excursion
    (end-of-line)
    (if (not (outline-invisible-p))
        (hide-subtree)
      (show-subtree))))

(defun oz-outline-reveal-headings (e)
  (interactive "e")
  (mouse-set-point e)
  (show-branches))

(provide 'oz-extra)

;;; Local Variables: ***
;;; mode: emacs-lisp ***
;;; byte-compile-dynamic-docstrings: nil ***
;;; byte-compile-compatibility: t ***
;;; End: ***
