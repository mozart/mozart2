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

;; Functions for running a Mozart sub-process
;;

(require 'oz)
(require 'comint)
(require 'compile)
(require 'oz-server)

(eval-and-compile
  (defvar oz-old-frame-title
    (cond (oz-gnu-emacs
           (cdr (assoc 'name (frame-parameters (car (visible-frame-list))))))
          (oz-lucid-emacs
           frame-title-format))
    "Saved Emacs frame title."))

;;}}}
;;{{{ Customization

(eval-and-compile
  (eval '(defgroup mozart nil
           "Running a Mozart sub-process."
           :group 'oz
           :prefix "oz-")))

(eval-and-compile
  (eval '(defcustom oz-prefix "."
           "*Directory where Mozart is installed.
Used as fallback if the environment variable OZHOME is not set."
           :type 'string
           :group 'mozart)))
(put 'oz-prefix 'variable-interactive
     "DMozart installation directory: ")

(eval-and-compile
  (eval '(defcustom oz-change-title t
           "*If non-nil, change the Emacs frame title while Mozart is running."
           :type 'boolean
           :group 'mozart)))
(put 'oz-change-title 'variable-interactive
     "XChange frame title while Mozart is running? (t or nil): ")
(defvar *oz-change-title* oz-change-title)

(eval-and-compile
  (eval '(defcustom oz-frame-title
           (concat "Oz Programming Interface (" oz-old-frame-title ")")
           "*String to be used as Emacs frame title while Mozart is running."
           :type 'string
           :group 'mozart)))
(put 'oz-frame-title 'variable-interactive
     "sFrame title to use while Mozart is running: ")
(defvar *oz-frame-title* oz-frame-title)

(eval-and-compile
  (eval '(defcustom oz-prepend-line t
           "*If non-nil, prepend a \\line directive to all Oz queries."
           :type 'boolean
           :group 'mozart)))
(put 'oz-prepend-line 'variable-interactive
     "XPrepend a \\line directive to all Oz queries? (t or nil): ")
(defvar *oz-prepend-line* oz-prepend-line)

(eval-and-compile
  (eval '(defcustom oz-default-host "localhost"
           "*Default name of host to use for creating socket connections."
           :type 'string
           :group 'mozart)))
(put 'oz-default-host 'variable-interactive
     "sDefault host name to use for socket connections: ")
(defvar *oz-default-host* oz-default-host)

(defvar *OZ_PI* (getenv "OZ_PI"))

(defvar *OZHOME*
  (or (getenv "OZ_HOME")
      (getenv "OZHOME")
      oz-prefix))

(defvar oz-platform
  (if (memq system-type '(ms-dos windows-nt)) "win32-i486"
    (and *OZHOME*
         (substring
          (shell-command-to-string
           (concat *OZHOME* "/bin/ozplatform")) 0 -1))))

(defun oz-platform ()
  (cond (oz-platform)
        ((memq system-type '(ms-dos windows-nt))
         (setq oz-platform "win32-i486")
         oz-platform)
        (*OZHOME*
         (setq oz-platform
               (substring
                (shell-command-to-string
                 (concat *OZHOME* "/bin/ozplatform")) 0 -1))
         oz-platform)
        (t (error "Cannot determine Oz platform"))))

(defconst oz-tmp-buffer " Oz Tmp")
(defun oz-tmp-buffer () (get-buffer-create oz-tmp-buffer))

(defun oz-escape-path-separator (s &rest l)
  (with-current-buffer (oz-tmp-buffer)
    (save-excursion
      (widen)
      (erase-buffer)
      (insert s)
      (let ((seps (cons path-separator l)) sep repl)
        (while seps
          (goto-char (point-min))
          (setq sep  (car seps)
                seps (cdr seps)
                repl (concat "\\" sep))
          (while (re-search-forward (regexp-quote sep) nil t)
            (replace-match repl t t))))
      (buffer-substring-no-properties (point-min) (point-max)))))

;(defvar *OZVERSION*
;  (or (getenv "OZVERSION") "@OZVERSION@"))

(defvar *OZVERSION*
  (or (getenv "OZVERSION") "2.0"))

(defvar *OZDOTOZ*
  (or (getenv "OZ_DOTOZ") (concat "~/.oz/" *OZVERSION*)))

(defvar *OZLOAD*
  (or (getenv "OZ_SEARCH_LOAD")
      (getenv "OZ_LOAD")
      (getenv "OZLOAD")
      (concat
       "cache="
       (oz-escape-path-separator
        (expand-file-name (concat *OZDOTOZ* "/cache")))
       path-separator
       "cache="
       (oz-escape-path-separator
        (expand-file-name
         (concat oz-prefix "/cache"))))))

(defvar *OZPATH*
  (or (getenv "OZ_SEARCH_PATH")
      (getenv "OZ_PATH")
      (getenv "OZPATH")
      (concat
       "." path-separator
       (oz-escape-path-separator
        (expand-file-name
         (concat oz-prefix "/share"))))))

(defvar *OZEMULATOR* (getenv "OZEMULATOR"))
(defvar *OZINIT* (getenv "OZINIT"))
(defvar *OZ_TRACE_LOAD* (getenv "OZ_TRACE_LOAD"))
(defvar *OZ_TRACE_MODULE* (getenv "OZ_TRACE_MODULE"))

(defvar *OZ_LD_LIBRARY_PATH*
  (or (getenv "LD_LIBRARY_PATH")
      (and oz-platform
           (concat
            (expand-file-name
             (concat *OZDOTOZ* "/platform/" (oz-platform) "/lib"))
            (let ((d *OZHOME*))
              (if (equal d "") (setq d nil))
              (if d
                  (concat
                   path-separator
                   (expand-file-name
                    (concat d "/platform/" (oz-platform) "/lib")))
                ""))))))

(defvar *OZ_DYLD_LIBRARY_PATH*
  (or (getenv "DYLD_LIBRARY_PATH")
      *OZ_LD_LIBRARY_PATH*))

(defvar *oz-root-functor* "x-oz://system/OPI.ozf")
(defvar *oz-gdb* nil) ;; nil,t,auto

(eval-and-compile
  (eval '(defcustom oz-other-buffer-size 35
           "*Percentage of screen to use for Oz Compiler/Emulator/Temp window."
           :type 'integer
           :group 'mozart)))
(put 'oz-other-buffer-size 'variable-interactive
     "nPercentage of screen to use for Oz windows: ")
(defvar *oz-other-buffer-size* oz-other-buffer-size)

(eval-and-compile
  (eval '(defcustom oz-popup-on-error t
           "*If non-nil, pop up Compiler resp. Emulator buffer upon error."
           :type 'boolean
           :group 'mozart)))
(put 'oz-popup-on-error 'variable-interactive
     "XPop up Oz buffers on error? (t or nil): ")
(defvar *oz-popup-on-error* oz-popup-on-error)

(eval-and-compile
  (eval '(defcustom oz-halt-timeout 30
           "*Number of seconds to wait for shutdown in oz-halt."
           :type 'integer
           :group 'mozart)))
(put 'oz-halt-timeout 'variable-interactive
     "nNumber of seconds to wait for shutdown of the Mozart sub-process: ")
(defvar *oz-halt-timeout* oz-halt-timeout)

(defvar *oz-compile-command* "ozc -c \"%s\"")
(defvar *oz-application-command* "%s")
(defvar *oz-engine-program*
  (if *OZHOME* (concat *OZHOME* "/bin/ozengine") "ozengine"))

;;}}}
;;{{{ Oz Profiles

(eval-and-compile
  (defvar oz-format-1 "%t\n\t\t   %h"))

(eval-and-compile
  (eval
   `(defcustom
      oz-profiles nil
      "*An alist of profiles for multiple Mozart versions"
      :group 'mozart
      :type
      '(repeat
        (list
         :tag "Profile"
         (symbol :tag "Name   ")
         (choice
          :tag "Type   "
          :value default
          (const default)
          (const installed)
          (const build))
        (set
         :tag "Options"
         :inline t
         (group
          (const :doc "Oz installation directory"
                 :format ,oz-format-1
                 OZHOME)
          directory)
         (group
          (const :doc "methods used by the resolver to resolve URIs"
                 :format ,oz-format-1
                 OZLOAD)
          (repeat
           :tag "Methods"
           (choice
            :tag "Method"
            (const :tag "User Cache" user-cache)
            (const :tag "Global Cache" global-cache)
            (group
             :tag "Cache"
             (const :tag "Cache" cache)
             (string :tag "Directory"))
            (group
             :tag "Root"
             (const :tag "Root" root)
             (string :tag "Directory"))
            (group
             :tag "Prefix"
             (const :tag "Prefix" prefix)
             (string :tag "Match String")
             (string :tag "Replacement String"))
            (group
             :tag "Pattern"
             (const :tag "Pattern" pattern)
             (string :tag "Match Pattern")
             (string :tag "Replacement Pattern"))
            (group
             :tag "All"
             (const :tag "All" all)
             (string :tag "Directory"))
            (const :tag "Block default lookup" block))))
         (group
          (const :doc "directories to search for \\insert directives"
                 :format ,oz-format-1
                 OZPATH)
          (repeat
           :tag "Directories"
           (choice
            (const  :tag "Current Directory"   current)
            (const  :tag "Global Installation" global)
            directory)))
         (group
          (const :doc "whether the resolver should output tracing information"
                 :format ,oz-format-1
                 OZ_TRACE_LOAD)
          boolean)
         (group
          (const :doc "whether the module manager should output tracing information"
                 :format ,oz-format-1
                 OZ_TRACE_MODULE)
          boolean)
         (group
          (const :doc "additional directories to search for dynamically linked libraries"
                 :format ,oz-format-1
                 LD_LIBRARY_PATH)
          (repeat :tag "Directories" directory))
         (group
          (const :doc "additional directories to search for MacOS X dylib libraries"
                 :format ,oz-format-1
                 DYLD_LIBRARY_PATH)
          (repeat :tag "Directories" directory))
          (group
           (const :doc "path to emulator.exe"
                  :format ,oz-format-1
                  OZEMULATOR)
           file)
          (group
           (const :doc "path to Init.ozf"
                  :format ,oz-format-1
                  OZINIT))
          (group
           (const :doc "additional directories to search for executable programs"
                  :format ,oz-format-1
                  PATH)
           (repeat
            :tag "Directories" directory))
          (group
           (const :tag "Change Title"
                  :doc "whether to change the Emacs frame title\nwhile Mozart is running"
                  :format ,oz-format-1
                  change-title)
           boolean)
          (group
           (const :tag "Frame Title"
                  :doc "string to be used as Emacs frame title\nwhile Mozart is running"
                  :format ,oz-format-1
                  frame-title)
           string)
          (group
           (const :tag "Prepend Line"
                  :doc "whether to prepend a \\line directive to all Oz queries"
                  :format ,oz-format-1
                  prepend-line)
           boolean)
          (group
           (const :tag "Default Host"
                  :doc "default name of host to use for creating socket connections"
                  :format ,oz-format-1
                  default-host)
           string)
          (group
           (const :tag "Source Directory"
                  :doc "directory containing the Mozart sources"
                  :format ,oz-format-1
                  source-dir)
           directory)
          (group
           (const :tag "Build Directory"
                  :doc "directory containing the Mozart build"
                  :format ,oz-format-1
                  build-dir)
           directory)
          (group
           (const :tag "Secondary Build Directory"
                  :doc "another directory containing a Mozart build.\nThis is useful when the Build Directory contains\nonly a partial build.  The Secondary Build Directory should\ncontain a full build that supplies the missing pieces."
                  :format ,oz-format-1
                  build-dir-too)
           directory)
          (group
           (const :tag "Root Functor"
                  :doc "URI of the root functor to load on startup"
                  :format ,oz-format-1
                  root-functor)
           (string :value "x-oz://system/OPI.ozf"))
          (group
           (const :tag "Run Under GDB"
                  :doc "whether to run Mozart under GDB for debugging the implementation"
                  :format ,oz-format-1
                  gdb)
           (choice
            (const :tag "No" nil)
            (const :tag "Yes" t)
            (const :tag "Yes + Auto Start" auto)))
          (group
           (const :tag "Other Buffer Size"
                  :doc "percentage of screen to use for Oz Compiler/Emulator/Temp window"
                  :format ,oz-format-1
                  other-buffer-size)
           integer)
          (group
           (const :tag "Popup On Error"
                  :doc "whether to pop up Compiler resp. Emulator buffer upon error"
                  :format ,oz-format-1
                  popup-on-error)
           boolean)
          (group
           (const :tag "Halt Timeout"
                  :doc "number of seconds to wait for shutdown in oz-halt"
                  :format ,oz-format-1
                  halt-timeout)
           integer)
          (group
           (const :tag "Compile Command"
                  :doc "default shell command to do a compilation\nThis may contain at most one occurrence of `%s', which is\nreplaced by the current buffer's file name"
                  :format ,oz-format-1
                  compile-command)
           (string :value "ozc -c %s"))
          (group
           (const :tag "Application Command"
                  :doc "default shell command to execute an Oz application\nThis may contain at most one occurrence of `%s', which\nis replaced by the current buffer's file name, minus the\n`.oz' or `.ozg' extension."
                  :format ,oz-format-1
                  application-command)
           (string :value "%s"))
          (group
           (const :tag "Engine Program"
                  :doc "default Oz engine to run the OPI"
                  engine-program)
           (string :value ,(concat oz-prefix "/bin/ozengine")))))))))

(defun oz-simple-directory (d)
  (if (string-equal (substring d -1) "/")
      (substring d 0 -1)
    d))

;; Silence the compiler warning below
(defvar methods)

(defun oz-push-method (m)
  (if methods (setq methods (cons path-separator methods)))
  (setq methods (cons m methods)))

;; Silence the compiler warning below
(defvar OZPATH)

(defun oz-dirs-to-search-path (l user global)
  (let ((methods nil)
        (l OZPATH) d)
    (while l
      (setq d (car l) l (cdr l))
      (cond ((eq d 'user)
             (setq d user))
            ((eq d 'global)
             (setq d global)))
      (if (stringp d)
          (oz-push-method
           (oz-simple-directory d))))
    (apply (function concat) (reverse methods))))

(defvar *OZ_PATH* nil)

(defvar oz-environment-variables
  '("PATH"
    "OZ_PI"
    "OZ_HOME" "OZHOME"
    "OZINIT"
    "OZ_SEARCH_LOAD" "OZ_LOAD" "OZLOAD"
    "OZ_SEARCH_PATH" "OZ_PATH" "OZPATH"
    "OZEMULATOR"
    "OZ_TRACE_LOAD"
    "OZ_TRACE_MODULE"
    "LD_LIBRARY_PATH"
    "DYLD_LIBRARY_PATH"))

(defun oz-environment-snapshot ()
  (mapcar
   (function (lambda (v) (cons v (getenv v))))
   oz-environment-variables))

;; Silence the compiler warning below
(defvar *oz-ignore-env*)

(defun oz-environment-install ()
  (setenv "OZ_PI" "1")
  (if (and *OZ_PATH* (not (equal *OZ_PATH* "")))
      (setenv "PATH" (concat *OZ_PATH* path-separator (getenv "PATH"))))
  (when (or *OZHOME* *oz-ignore-env*)
    (setenv "OZHOME" *OZHOME*)
    (setenv "OZ_HOME" *OZHOME*))
  (when (or *OZLOAD* *oz-ignore-env*)
    (setenv "OZ_SEARCH_LOAD" *OZLOAD*)
    (setenv "OZ_LOAD" *OZLOAD*)
    (setenv "OZLOAD" *OZLOAD*))
  (when (or *OZPATH* *oz-ignore-env*)
    (setenv "OZ_SEARCH_PATH" *OZPATH*)
    (setenv "OZ_PATH" *OZPATH*)
    (setenv "OZPATH" *OZPATH*))
  (when (or *OZINIT* *oz-ignore-env*)
    (setenv "OZINIT" *OZINIT*))
  (setenv "OZ_TRACE_LOAD" *OZ_TRACE_LOAD*)
  (setenv "OZ_TRACE_MODULE" *OZ_TRACE_MODULE*)
  (when (and *OZ_LD_LIBRARY_PATH* (not (equal *OZ_LD_LIBRARY_PATH* "")))
    (let ((p (getenv "LD_LIBRARY_PATH")))
      (setenv "LD_LIBRARY_PATH"
              (if p
                  (concat *OZ_LD_LIBRARY_PATH* path-separator p)
                *OZ_LD_LIBRARY_PATH*))))
  (when (and *OZ_DYLD_LIBRARY_PATH* (not (equal *OZ_DYLD_LIBRARY_PATH* "")))
    (let ((p (getenv "DYLD_LIBRARY_PATH")))
      (setenv "DYLD_LIBRARY_PATH"
              (if p
                  (concat *OZ_DYLD_LIBRARY_PATH* path-separator p)
                *OZ_DYLD_LIBRARY_PATH*))))
  (when (or *OZEMULATOR* *oz-ignore-env*)
    (setenv "OZEMULATOR"
            (and (not (equal *OZEMULATOR* "")) *OZEMULATOR*))))

(defvar oz-elisp-variables
  '(*OZHOME*
    *OZLOAD*
    *OZPATH*
    *OZINIT*
    *OZ_TRACE_LOAD*
    *OZ_TRACE_MODULE*
    *OZ_LD_LIBRARY_PATH*
    *OZ_DYLD_LIBRARY_PATH*
    *OZEMULATOR*
    *OZ_PATH*
    *oz-change-title*
    *oz-frame-title*
    *oz-prepend-line*
    *oz-default-host*
    *oz-root-functor*
    *oz-gdb*
    *oz-other-buffer-size*
    *oz-popup-on-error*
    *oz-halt-timeout*
    *oz-compile-command*
    *oz-application-command*
    *oz-engine-program*))

(defun oz-elisp-snapshot ()
  (mapcar
   (function (lambda (v) (cons v (symbol-value v))))
   oz-elisp-variables))

(defvar *oz-snapshot* nil)

(defun oz-snapshot-take ()
  (setq *oz-snapshot*
        (list (oz-environment-snapshot)
              (oz-elisp-snapshot))))

(defun oz-environment-snapshot-revert (l)
  (while l
    (setenv (caar l) (cdar l))
    (setq l (cdr l))))

(defun oz-elisp-snapshot-revert (l)
  (while l
    (set (caar l) (cdar l))
    (setq l (cdr l))))

(defun oz-snapshot-revert ()
  (oz-environment-snapshot-revert (car *oz-snapshot*))
  (oz-elisp-snapshot-revert (cadr *oz-snapshot*))
  (setq *oz-snapshot* nil))

(defvar *oz-ignore-env* nil)

(defun oz-profile-install (profile)
  (let* ((name  (car  profile))
         (type  (cadr profile))
         (alist (cddr profile))
         (OZHOME            (cadr (assq 'OZHOME              alist)))
         (OZLOAD            (cadr (assq 'OZLOAD              alist)))
         (OZPATH            (cadr (assq 'OZPATH              alist)))
         (OZ_TRACE_LOAD     (cadr (assq 'OZ_TRACE_LOAD       alist)))
         (OZ_TRACE_MODULE   (cadr (assq 'OZ_TRACE_MODULE     alist)))
         (LD_LIBRARY_PATH   (cadr (assq 'LD_LIBRARY_PATH     alist)))
         (DYLD_LIBRARY_PATH (cadr (assq 'DYLD_LIBRARY_PATH   alist)))
         (OZEMULATOR        (cadr (assq 'OZEMULATOR          alist)))
         (OZINIT            (cadr (assq 'OZINIT              alist)))
         (PATH              (cadr (assq 'PATH                alist)))
         (ignore-env              (assq 'ignore-env          alist))
         (change-title            (assq 'change-title        alist))
         (frame-title             (assq 'frame-title         alist))
         (prepend-line            (assq 'prepend-line        alist))
         (default-host            (assq 'default-host        alist))
         (source-dir              (assq 'source-dir          alist))
         (build-dir               (assq 'build-dir           alist))
         (build-dir-too           (assq 'build-dir-too       alist))
         (root-functor            (assq 'root-functor        alist))
         (gdb                     (assq 'gdb                 alist))
         (other-buffer-size       (assq 'other-buffer-size   alist))
         (popup-on-error          (assq 'popup-on-error      alist))
         (halt-timeout            (assq 'halt-timeout        alist))
         (compile-command         (assq 'compile-command     alist))
         (application-command     (assq 'application-command alist))
         (engine-program          (assq 'engine-program      alist))
         )
    (cond ((eq type 'default)
           (or ignore-env (setq ignore-env '(ignore-env nil)))
           )
          ((eq type 'installed)
           (or OZHOME (error "No OZHOME in profile"))
           (or OZLOAD (setq OZLOAD '(user-cache global-cache)))
           (or OZPATH (setq OZPATH '(current global)))
           (or LD_LIBRARY_PATH (setq LD_LIBRARY_PATH '(user global)))
           (or DYLD_LIBRARY_PATH (setq DYLD_LIBRARY_PATH LD_LIBRARY_PATH))
           (or PATH (setq PATH '(user global)))
           (or ignore-env (setq ignore-env '(ignore-env t)))
           (or compile-command (setq compile-command (list 'compile-command (concat OZHOME "/bin/ozc -c \"%s\""))))
           (or application-command (setq application-command (list 'application-command "%s")))
           (or engine-program (setq engine-program (list 'engine-program (concat OZHOME "/bin/ozengine"))))
           )
          ((eq type 'build)
           (or ignore-env (setq ignore-env '(ignore-env t)))
           (or build-dir (error "No build-dir in profile"))
           (or OZLOAD (setq OZLOAD
                            `((prefix "x-oz://system/"
                                      ,(concat (cadr build-dir) "/share/lib/"))
                              (prefix "x-oz://system/"
                                      ,(concat (cadr build-dir) "/share/tools/"))
                              (prefix "x-oz://boot/"
                                      ,(concat (cadr build-dir) "/platform/emulator/"))
                              ,@(and
                                 build-dir-too
                                 `((prefix "x-oz://system/"
                                           ,(concat (cadr build-dir-too) "/share/lib/"))
                                   (prefix "x-oz://system/"
                                           ,(concat (cadr build-dir-too) "/share/tools/"))
                                   (prefix "x-oz://boot/"
                                           ,(concat (cadr build-dir-too) "/platform/emulator/"))))
                              ,@(and
                                 source-dir
                                 `((prefix "x-oz://system/images/inspector/"
                                           ,(concat (cadr source-dir)
                                                    "/share/tools/inspector/images/"))
                                   (prefix "x-oz://system/images/"
                                           ,(concat (cadr source-dir)
                                                    "/share/lib/images/"))
                                   (prefix "x-oz://system/images/"
                                           ,(concat (cadr source-dir)
                                                    "/share/tools/images/"))
                                   ))
                              user-cache
                              ,@(and OZHOME '(global-cache)))))
           (or OZPATH (setq OZPATH '(current)))
           (or OZINIT
               (let (f)
                 (setq f (concat (cadr build-dir) "/share/lib/Init.ozf"))
                 (if (file-exists-p f)
                     (setq OZINIT f)
                   (when build-dir-too
                     (setq f (concat (cadr build-dir-too) "/share/lib/Init.ozf"))
                     (if (file-exists-p f)
                         (setq OZINIT f))))))
           (or LD_LIBRARY_PATH
               (setq LD_LIBRARY_PATH '(user global)))
           (or DYLD_LIBRARY_PATH
               (setq DYLD_LIBRARY_PATH LD_LIBRARY_PATH))
           (or PATH (setq PATH '(user global)))
           (or OZEMULATOR
               (setq OZEMULATOR (concat (cadr build-dir) "/platform/emulator/emulator.exe")))
           )
          (t (error "Unkown profile type: %s" type)))

    (setq *oz-ignore-env* (cadr ignore-env))
    (if (or OZHOME *oz-ignore-env*) (setq *OZHOME* OZHOME))
    (if *OZHOME* (setq *OZHOME* (oz-simple-directory *OZHOME*)))
    (setq *OZINIT*
          (or OZINIT
              (concat *OZHOME* "/share/Init.ozf")))
    (if OZLOAD
        (let ((blocks nil)
              (methods nil)
              (specs OZLOAD) spec)
          (while specs
            (setq spec (car specs) specs (cdr specs))
            (cond ((eq spec 'user-cache)
                   (oz-push-method (concat "cache=" *OZDOTOZ* "/cache")))
                  ((eq spec 'global-cache)
                   (if *OZHOME*
                       (oz-push-method
                        (concat "cache="
                                (oz-escape-path-separator
                                 (concat *OZHOME* "/cache"))))))
                  ((eq spec 'block)
                   (setq blocks t))
                  ((consp spec)
                   (cond ((eq (car spec) 'cache)
                          (oz-push-method
                           (concat "cache="
                                   (oz-escape-path-separator
                                    (oz-simple-directory (cadr spec))))))
                         ((eq (car spec) 'root)
                          (oz-push-method
                           (concat "root="
                                   (oz-escape-path-separator
                                    (oz-simple-directory (cadr spec))))))
                         ((eq (car spec) 'prefix)
                          (oz-push-method
                           (concat "prefix="
                                   (oz-escape-path-separator
                                    (cadr spec) "=")
                                   "="
                                   (oz-escape-path-separator
                                    (cadr (cdr spec))))))
                         ((eq (car spec) 'pattern)
                          (oz-push-method
                           (concat "pattern="
                                   (oz-escape-path-separator
                                    (cadr spec) "=")
                                   "="
                                   (oz-escape-path-separator
                                    (cadr (cdr spec))))))
                         ((eq (car spec) 'all)
                          (oz-push-method
                           (concat "all="
                                   (oz-escape-path-separator
                                    (oz-simple-directory (cadr spec))))))))
                  (t (error "unexpected OZLOAD method: %s" spec))))
          (if blocks (oz-push-method "="))
          (setq *OZLOAD* (apply (function concat) (reverse methods)))
          ))
    (if OZPATH (setq *OZPATH* (oz-dirs-to-search-path
                               OZPATH nil
                               (and *OZHOME*
                                    (concat *OZHOME* "/share")))))
    (if OZ_TRACE_LOAD (setq *OZ_TRACE_LOAD* ""))
    (if OZ_TRACE_MODULE (setq *OZ_TRACE_MODULE* ""))
    (if LD_LIBRARY_PATH
        (setq *OZ_LD_LIBRARY_PATH*
              (oz-dirs-to-search-path
               LD_LIBRARY_PATH
               (expand-file-name
                (concat *OZDOTOZ* "/platform/" (oz-platform) "/lib"))
               (and *OZHOME*
                    (expand-file-name
                     (concat *OZHOME* "/platform/" (oz-platform) "/lib"))))))
    (if DYLD_LIBRARY_PATH
        (setq *OZ_DYLD_LIBRARY_PATH*
              (oz-dirs-to-search-path
               DYLD_LIBRARY_PATH
               (expand-file-name
                (concat *OZDOTOZ* "/platform/" (oz-platform) "/lib"))
               (and *OZHOME*
                    (expand-file-name
                     (concat *OZHOME* "/platform/" (oz-platform) "/lib"))))))
    (if OZEMULATOR (setq *OZEMULATOR* OZEMULATOR))
    (if PATH
        (setq *OZ_PATH*
              (oz-dirs-to-search-path
               PATH
               (expand-file-name (concat *OZDOTOZ* "/bin"))
               (and *OZHOME*
                    (expand-file-name
                     (concat *OZHOME* "/bin"))))))
    (setq *oz-change-title*
          (if change-title (cadr change-title) oz-change-title))
    (setq *oz-frame-title*
          (if frame-title  (cadr frame-title)  oz-frame-title))
    (setq *oz-prepend-line*
          (if prepend-line (cadr prepend-line) oz-prepend-line))
    (setq *oz-default-host*
          (if default-host (cadr default-host) oz-default-host))
    (if root-functor
        (setq *oz-root-functor* (cadr root-functor)))
    (if gdb (setq *oz-gdb* (cadr gdb)))
    (setq *oz-other-buffer-size*
          (if other-buffer-size (cadr other-buffer-size) oz-other-buffer-size))
    (setq *oz-popup-on-error*
          (if popup-on-error (cadr popup-on-error) oz-popup-on-error))
    (setq *oz-halt-timeout*
          (if halt-timeout (cadr halt-timeout) oz-halt-timeout))
    (if compile-command
        (setq *oz-compile-command* (cadr compile-command)))
    (if application-command
        (setq *oz-application-command* (cadr application-command)))
    (if engine-program
        (setq *oz-engine-program* (cadr engine-program)))
    )
  (oz-environment-install)
  )

(defvar oz-current-profile nil)

(defun oz-set-profile (name)
  "Select and install a profile from the list `oz-profiles'
of user-defined profiles. NAME is the name of a profile, or
nil to revert to the defaults."
  (interactive
   (list (completing-read
          "Profile: "
          (mapcar
           (function (lambda (p) (list (format "%s" (car p)))))
           oz-profiles) nil t)))
  (when (oz-is-running)
    (if (y-or-n-p "Oz is currently running.  Kill it?")
        (oz-halt t)
      (error "Cannot install a profile while Oz is running")))
  (oz-snapshot-revert)
  (setq oz-current-profile name)
  (oz-snapshot-take)
  (when (and name (not (equal name "")))
    (let ((profile (assq (intern name) oz-profiles)))
      (if profile (oz-profile-install profile)
        (error "Unknown profile: %s" name)))))

;;}}}
;;{{{ Variables/Initialization

(defvar oz-emulator-buffer "*Oz Emulator*"
  "Name of the Oz Emulator buffer.")

(defvar oz-compiler-buffer "*Oz Compiler*"
  "Name of the Oz Compiler buffer.")

(defvar oz-compiler-buffers nil
  "List of buffers in which Oz Compilers have been started.")

(defvar oz-temp-buffer "*Oz Temp*"
  "Name of the Oz temporary buffer.")

(defvar oz-buffered-send-string nil
  "List of buffered calls to oz-send-string.
These are performed only when the Oz Compiler is known to be running.")

(defvar oz-emulator-filter-hook nil
  "If non-nil, hook used as second process filter for the Oz Emulator.
This is set when gdb is active.")

(defconst oz-error-string (char-to-string 17)
  "Regex to recognize error messages from Oz Compiler and Emulator.
Used for popping up the corresponding buffer.")

(defconst oz-remove-pattern
  (concat oz-error-string "\\|"
          (char-to-string 18) "\\|" (char-to-string 19) "\\|"
          ;; Irix outputs garbage when sending EOF:
          "\\" (char-to-string 4) (char-to-string 8) (char-to-string 8) "\\|"
          ;; Under Windows, lines may be terminated by CRLF:
          (char-to-string 13) "\\|"
          ;; This is a directive we inserted ourselves:
          "\\\\line.*% fromemacs\n")
  "Regex specifying what to remove from Compiler and Emulator output.
All strings matching this regular expression are removed.")

(defconst oz-socket-pattern
  "'oz-socket \\(\"\\([^\"]*\\)\" \\)?\\([0-9]+\\) \\([0-9]+\\)'"
  "Regex for reading the information about the compiler socket.")

(defconst oz-show-temp-pattern
  "\'oz-show-temp \\([^ ]*\\)\'"
  "Regex for reading messages from the Oz compiler.")

(defconst oz-bar-pattern
  "\'oz-bar \\(.*\\) \\([0-9]+\\) \\([0-9]+\\|~1\\) \\([^ ]*\\)\'"
  "Regex for reading messages from the Oz debugger or profiler.")

;;}}}
;;{{{ Setting the Frame Title

(defun oz-set-title (frame-title)
  "Set the title of the Emacs frame."
  (cond ((not *oz-change-title*) t)
        (oz-gnu-emacs
         (mapcar (function (lambda (scr)
                             (modify-frame-parameters
                              scr
                              (list (cons 'name frame-title)))))
                 (visible-frame-list)))
        (oz-lucid-emacs
         (setq frame-title-format frame-title))))

;;}}}
;;{{{ Locating Errors

(defvar oz-compiler-output-start nil
  "Position in the Oz Compiler buffer where the last run's output began.")
(make-variable-buffer-local 'oz-compiler-output-start)

(defconst oz-error-intro-pattern "\\(error\\|warning\\) \\*\\*\\*\\*\\*"
  "Regular expression for finding error messages.")

(defconst oz-error-pattern
  (concat "in "
          "\\(file \"\\([^\"\n]+\\)\",? *\\)?"
          "line \\([0-9]+\\)"
          "\\(,? *column \\([0-9]+\\)\\)?")
  "Regular expression matching error coordinates.")

(defun oz-compilation-parse-errors (&optional limit-search find-at-least)
  "Parse the current buffer as Mozart error messages.
See variable `compilation-parse-errors-function' for the interface it uses."
  (setq compilation-error-list nil)
  (message "Parsing error messages...")
  ;; Don't reparse messages already seen at last parse.
  (goto-char (max (or oz-compiler-output-start (point-min))
                  (or compilation-parsing-end 0)))
  (let ((num-found 0))
    (while (re-search-forward
            oz-error-pattern
            (and (or (null find-at-least)
                     (>= num-found find-at-least)) limit-search) t)
      (let* ((file-string (oz-match-string 2))
             (line (string-to-number (oz-match-string 3)))
             (column-string (oz-match-string 5))
             (column (and column-string (string-to-number column-string)))
             (error-marker (save-excursion
                             (and (oz-goto-error-start)
                                  (progn (beginning-of-line)
                                         (point-marker)))))
             (buffer (and file-string
                          (oz-find-buffer-or-file file-string nil)))
             (error-data
              (cond ((not error-marker) nil)
                    ((not file-string)
                     (list error-marker))
                    (buffer
                     (with-current-buffer buffer
                       (save-excursion
                         (save-restriction
                           (widen)
                           (goto-line line)
                           (if (and column (> column 0))
                               (forward-char column))
                           (cons error-marker (point-marker))))))
                    (t
                     (let* ((file (oz-normalize-file-name file-string))
                            (filedata (list file default-directory))
                            (error-data (if column
                                            (list filedata line column)
                                          (list filedata line))))
                       (cons error-marker error-data))))))
        (if error-data
            (setq num-found (1+ num-found)
                  compilation-error-list
                  (cons error-data compilation-error-list))))))
  (setq compilation-error-list (nreverse compilation-error-list))
  (setq compilation-parsing-end (point))
  (message "Parsing error messages...done"))

(defun oz-goto-error-start ()
  ;; if point is in the middle of an error message (in the compiler buffer),
  ;; then it is moved to the start of the message.
  (let ((errstart
         (save-excursion
           (beginning-of-line)
           (if (looking-at "%\\*\\*")
               (re-search-backward oz-error-intro-pattern nil t)))))
    (if errstart (goto-char errstart))))

;;}}}
;;{{{ Utilities

(defun oz-line-region (arg)
  ;; Return starting and ending positions of ARG lines surrounding point.
  ;; Positions are returned as a pair ( START . END ).
  (save-excursion
    (let (start end)
      (cond ((> arg 0)
             (beginning-of-line)
             (setq start (point))
             (forward-line (1- arg))
             (end-of-line)
             (setq end (point)))
            ((= arg 0)
             (setq start (point))
             (setq end (point)))
            ((< arg 0)
             (end-of-line)
             (setq end (point))
             (forward-line arg)
             (setq start (point))))
      (cons start end))))

(defun oz-paragraph-region (arg)
  ;; Return starting and ending positions of ARG paragraphs surrounding point.
  ;; Positions are returned as a pair ( START . END ).
  (save-excursion
    (let (start end)
      (cond ((> arg 0)
             (backward-paragraph 1)
             (setq start (point))
             (forward-paragraph arg)
             (setq end (point)))
            ((= arg 0)
             (setq start (point))
             (setq end (point)))
            ((< arg 0)
             (forward-paragraph (1- arg))
             (setq start (point))
             (backward-paragraph (1- arg))
             (setq end (point))))
      (cons start end))))

(defun oz-get-region (start end)
  ;; Return the region from START to END from the current buffer as a string.
  ;; Leading and terminating whitespace is trimmed from the string and
  ;; a \\line directive is prepended to it.
  (save-excursion
    (goto-char start)
    (skip-chars-forward " \t\n")
    (if (/= (count-lines start (point)) 0)
        (progn
          (beginning-of-line)
          (setq start (point))))
    (goto-char end)
    (skip-chars-backward " \t\n")
    (setq end (point)))
  (if *oz-prepend-line*
      (concat "\\line " (number-to-string (1+ (count-lines 1 start)))
              " '" (or (buffer-file-name) (buffer-name)) "' % fromemacs\n"
              (buffer-substring start end))
    (buffer-substring start end)))

(defun oz-normalize-file-name (file)
  ;; Collapse multiple slashes to one, to handle non-Emacs file names.
  (save-match-data
    ;; Use arg 1 so that we don't collapse // at the start of the file name.
    ;; That is significant on some systems.
    ;; However, /// at the beginning is supposed to mean just /, not //.
    (if (string-match "^///+" file)
        (setq file (replace-match "/" t t file)))
    (while (string-match "//+" file 1)
      (setq file (replace-match "/" t t file)))
    file))

(defun oz-find-buffer-or-file (name visit)
  ;; Try to find a buffer or file named NAME.
  ;; If VISIT is nil, only return an existing buffer,
  ;; else try to locate NAME on the file system.
  (or (get-buffer name)
      (find-buffer-visiting name)
      (and visit
           (let ((find-file-run-dired nil))
             (find-file-noselect (oz-normalize-file-name name))))))

(defun oz-match-string (num &optional string)
  ;; Return string of text matched by last search.
  ;; NUM specifies which parenthesized expression in the last regexp.
  ;; Value is nil if NUMth pair didn't match, or there were less than NUM
  ;; pairs.  Zero means the entire text matched by the whole regexp or whole
  ;; string.  STRING should be given if the last search was by `string-match'
  ;; on STRING.
  (if (match-beginning num)
      (if string
          (substring string (match-beginning num) (match-end num))
        (buffer-substring (match-beginning num) (match-end num)))))

;;}}}
;;{{{ Run/Halt Oz

(defun run-oz ()
  "Run Mozart as a sub-process.
Handle input and output via the Oz Emulator buffer."
  (interactive)
  (save-excursion
    (oz-start-if-not-running))
  (oz-create-oz-buffer))

(defun oz-create-oz-buffer ()
  (or (eq major-mode 'oz-mode)
      (eq major-mode 'oz-gump-mode)
      (eq major-mode 'ozm-mode)
      (oz-new-buffer)))

(defun oz-halt (force)
  "Halt the Mozart sub-process.
With no prefix argument, feed an `{Application.exit 0}' statement and
wait for the process to terminate.  Waiting time is limited by variable
`oz-halt-timeout'; after this delay, the process is sent a SIGHUP if
still living.

With C-u as prefix argument, send the process a SIGHUP without delay.
With C-u C-u as prefix argument, send it a SIGKILL instead."
  (interactive "P")
  (if (oz-is-running)
      (progn
        (message "Halting Oz ...")
        (if (not force)
            (let* ((i *oz-halt-timeout*)
                   (proc (get-buffer-process oz-emulator-buffer)))
              (oz-send-string " functor _ require Application prepare {Application.exit 0} end " t)
              (while (and (eq (process-status proc) 'run)
                          (> i 0))
                (message "Halting Oz ... %s" i)
                (sleep-for 1)
                (setq i (1- i)))))
        (if (and (consp force)
                 (> (car force) 4))
            (progn
              (kill-process oz-emulator-buffer)
              (message "Oz killed."))
          (delete-process oz-emulator-buffer)
          (message "Oz halted.")))
    (message "Oz is not running."))
  (cond ((get-buffer oz-temp-buffer)
         (delete-windows-on oz-temp-buffer)
         (kill-buffer oz-temp-buffer)))
  (oz-bar-remove)
  (setq oz-buffered-send-string nil)
  (oz-set-title oz-old-frame-title))

(defun oz-is-running ()
  (get-buffer-process oz-emulator-buffer))

(defun oz-start-if-not-running ()
  (if (not (oz-is-running))
      (progn
        (oz-set-profile oz-current-profile)
        (cond (*oz-gdb*
               (oz-start-gdb-emulator)
               (oz-prepare-emulator-buffer
                (process-filter (get-buffer-process oz-emulator-buffer)) t))
              (t
               (setq oz-emulator-buffer "*Oz Emulator*")
               (oz-make-comint *oz-engine-program* *oz-root-functor*)
               (oz-prepare-emulator-buffer 'oz-filter t)))
        (oz-set-title *oz-frame-title*)
        (message "Oz started."))))

(defun oz-attach ()
  (let (host port)
    (cond ((>= (length command-line-args-left) 1)
           (setq host *oz-default-host*
                 port (string-to-number (car command-line-args-left))
                 command-line-args-left (cdr command-line-args-left)))
          (t
           (error "Missing port argument to oz-attach")))
    (oz-make-comint (cons host port))
    (oz-prepare-emulator-buffer 'oz-filter nil)
    (set-process-query-on-exit-flag (get-buffer-process oz-emulator-buffer) nil)))

(defun oz-make-comint (program &rest switches)
  (if (get-buffer oz-emulator-buffer)
      (progn
        (delete-windows-on oz-emulator-buffer)
        (kill-buffer oz-emulator-buffer)))
  (apply 'make-comint "Oz Emulator" program nil switches))

(defun oz-prepare-emulator-buffer (filter show)
  (let ((proc (get-buffer-process oz-emulator-buffer)))
    (setq oz-emulator-filter-hook filter)
    (set-process-filter proc 'oz-emulator-filter))
  (if show
      (oz-buffer-show (get-buffer oz-emulator-buffer)))
  (bury-buffer oz-emulator-buffer))

(defun oz-socket (host port port2)
  (let ((bs oz-compiler-buffers) (newbs nil))
    (while bs
      (if (not (comint-check-proc (car bs)))
          (kill-buffer (car bs))
        (setq newbs (cons (car bs) newbs)))
      (setq bs (cdr bs)))
    (setq oz-compiler-buffers newbs))
  (let ((buffer (generate-new-buffer "*Oz Compiler*")))
    (setq oz-compiler-buffers (cons buffer oz-compiler-buffers))
    (with-current-buffer buffer
      (save-excursion
        (compilation-mode)
        (setq buffer-read-only nil)
        (set (make-local-variable 'compilation-parse-errors-function)
            'oz-compilation-parse-errors)))
    (comint-exec buffer (buffer-name buffer) (cons host port) nil nil)
    (let ((proc (get-buffer-process buffer)))
      (set-process-query-on-exit-flag proc nil)
      (set-process-filter proc 'oz-compiler-filter))
    (oz-buffer-show buffer)
    (bury-buffer buffer)
    (let ((xs oz-buffered-send-string))
      (setq oz-buffered-send-string nil)
      (while xs
        (oz-send-string (car (car xs)) (cdr (car xs)))
        (setq xs (cdr xs)))))
  (oz-server-open host port2))

;;}}}
;;{{{ Filtering Process Output

(defun oz-emulator-filter (proc string)
  ;; look for oz-socket:
  (let ((start 0))
    (while (string-match oz-socket-pattern string start)
      (let ((host (or (oz-match-string 2 string) *oz-default-host*))
            (port (string-to-number (oz-match-string 3 string)))
            (port2 (string-to-number (oz-match-string 4 string))))
        (setq start (match-beginning 0))
        (setq string (concat (substring string 0 start)
                             (substring string (match-end 0))))
        (save-excursion
          (oz-socket host port port2)))))
  (funcall oz-emulator-filter-hook proc string))

(defun oz-compiler-filter (proc string)
  ;; look for oz-show-temp:
  (let ((start 0))
    (while (string-match oz-show-temp-pattern string start)
      (let ((filename (oz-normalize-file-name (oz-match-string 1 string))))
        (setq start (match-beginning 0))
        (setq string (concat (substring string 0 start)
                             (substring string (match-end 0))))
        (save-excursion
          (let ((buf (or (get-buffer oz-temp-buffer)
                         (generate-new-buffer oz-temp-buffer))))
            (oz-buffer-show buf)
            (set-buffer buf))
          (insert-file-contents filename t nil nil t)
          (delete-file filename)
          (cond ((string-match "\\.ozi$" filename) (oz-mode))
                ((string-match "\\.ozm$" filename) (ozm-mode)))))))
  ;; look for oz-bar:
  (let ((start 0))
    (while (string-match oz-bar-pattern string start)
      (let ((file   (oz-match-string 1 string))
            (line   (string-to-number (oz-match-string 2 string)))
            (column (let ((c (oz-match-string 3 string)))
                      (if (string-equal c "~1")
                          -1
                        (string-to-number c))))
            (state  (oz-match-string 4 string)))
        (setq start (match-beginning 0))
        (setq string (concat (substring string 0 start)
                             (substring string (match-end 0))))
        (with-current-buffer (process-buffer proc)
          (save-excursion
            (oz-bar file line column state))))))
  (oz-filter proc string))

(defun oz-filter (proc string)
  (let ((old-buffer (current-buffer)))
    (unwind-protect
        (let (moving errs-found start-of-output)
          (set-buffer (process-buffer proc))
          (setq moving (= (point) (process-mark proc)))
          (save-excursion
            ;; insert the text, moving the process marker:
            (goto-char (process-mark proc))
            (setq start-of-output (point))
            (insert-before-markers string)
            (set-marker (process-mark proc) (point))

            ;; look for error messages in output:
            (goto-char start-of-output)
            (setq errs-found
                  (and *oz-popup-on-error*
                       (re-search-forward oz-error-string nil t)
                       (match-beginning 0)))

            ;; remove escape characters:
            (goto-char start-of-output)
            (while (re-search-forward oz-remove-pattern nil t)
              (replace-match "" nil t)))

          (if errs-found
              (progn
                (oz-buffer-show (current-buffer))
                (set-window-start (get-buffer-window (current-buffer))
                                  errs-found)
                (set-window-point (get-buffer-window (current-buffer))
                                  errs-found))
            (if moving
                (goto-char (process-mark proc)))))
      (set-buffer old-buffer))))

;;}}}
;;{{{ Buffers

(defun oz-buffer-show (buffer)
  (if (and buffer (not (get-buffer-window buffer)))
      (let ((win (or (get-buffer-window oz-emulator-buffer)
                     (let ((bs oz-compiler-buffers) com)
                       (while (and (not com) bs)
                         (setq com (get-buffer-window (car bs)))
                         (setq bs (cdr bs)))
                       com)
                     (get-buffer-window oz-temp-buffer)
                     (split-window (get-largest-window)
                                   (/ (* (window-height (get-largest-window))
                                         (- 100 *oz-other-buffer-size*))
                                      100)))))
        (set-window-buffer win buffer)
        (set-buffer buffer)
        (set-window-point win (point-max))
        (bury-buffer buffer))))

(defun oz-toggle-compiler ()
  "Toggle visibility of the Oz Compiler window.
If the compiler buffer is not visible in any window, then display it.
If it is, then delete the corresponding window."
  (interactive)
  (oz-toggle-window oz-compiler-buffer))

(defun oz-toggle-emulator ()
  "Toggle visibility of the Oz Emulator window.
If the emulator buffer is not visible in any window, then display it.
If it is, then delete the corresponding window."
  (interactive)
  (oz-toggle-window oz-emulator-buffer))

(defun oz-toggle-temp ()
  "Toggle visibility of the Oz Temp window.
If the temporary buffer is not visible in any window, then show it.
If it is, then delete the corresponding window."
  (interactive)
  (oz-toggle-window oz-temp-buffer))

(defun oz-toggle-window (buffername)
  (let ((buffer (get-buffer buffername)))
    (if buffer
        (let ((win (get-buffer-window buffername)))
          (if win
              (with-current-buffer buffer
                (save-excursion
                  (if (= (window-point win) (point-max))
                      (delete-windows-on buffername)
                    (set-window-point win (point-max)))))
            (oz-buffer-show (get-buffer buffername)))))))

;;}}}
;;{{{ Feeding to the Compiler

(defun oz-zmacs-stuff ()
  (if (boundp 'zmacs-region-stays) (setq zmacs-region-stays t)))

(defun oz-feed-buffer ()
  "Feed the current buffer to the Oz Compiler."
  (interactive)
  (let ((file (buffer-file-name)))
    (if (and *oz-prepend-line* file (buffer-modified-p)
             (y-or-n-p (format "Save buffer %s first? " (buffer-name))))
        (save-buffer))
    (if (and *oz-prepend-line* file (not (buffer-modified-p)))
        (oz-feed-file file)
      (oz-feed-region (point-min) (point-max))))
  (oz-zmacs-stuff))

(defun oz-feed-region (start end)
  "Feed the current region to the Oz Compiler."
  (interactive "r")
  (oz-send-string (oz-get-region start end))
  (oz-zmacs-stuff))

(defun oz-feed-line (arg)
  "Feed the current line to the Oz Compiler.
With ARG, feed that many lines.  If ARG is negative, feed that many
preceding lines as well as the current line."
  (interactive "p")
  (let ((region (oz-line-region arg)))
    (oz-feed-region (car region) (cdr region))))

(defun oz-feed-paragraph (arg)
  "Feed the current paragraph to the Oz Compiler.
If the point is exactly between two paragraphs, feed the preceding
paragraph.  With ARG, feed that many paragraphs.  If ARG is negative,
feed that many preceding paragraphs as well as the current paragraph."
  (interactive "p")
  (let ((region (oz-paragraph-region arg)))
    (oz-feed-region (car region) (cdr region))))

(if (memq system-type '(ms-dos windows-nt))
    (defun oz-encode-string (s)
      (encode-coding-string string buffer-file-coding-system))
  (defun oz-encode-string (s) s))

(defun oz-send-string (string &optional system)
  "Feed STRING to the Oz Compiler, restarting Mozart if it died.
If SYSTEM is non-nil, it is a command for the system and is to be
compiled using a default set of switches."
  (interactive "sString to feed: \nP")
  (oz-start-if-not-running)
  (if (not (get-buffer-process oz-compiler-buffer))
      (setq oz-buffered-send-string
            (nconc oz-buffered-send-string (list (cons string system))))
    (let ((proc (get-buffer-process oz-compiler-buffer))
          (eof (concat (char-to-string 4) "\n")))
      (with-current-buffer oz-compiler-buffer
        (save-excursion
          (setq compilation-last-buffer (current-buffer))
          (setq oz-compiler-output-start
                (marker-position
                 (process-mark (get-buffer-process (current-buffer)))))
          (setq compilation-error-list nil)))
      (if system
          (comint-send-string
           proc
           (concat "\\localSwitches\n"
                   "\\switch +threadedqueries -verbose "
                   "-expression -runwithdebugger\n"
                   (oz-encode-string string)))
        (comint-send-string proc (oz-encode-string string)))
      (comint-send-string proc "\n")
      (comint-send-string proc eof))))


(defun oz-to-coresyntax-buffer ()
  "Display the core syntax expansion of the current buffer."
  (interactive)
  (oz-to-coresyntax-region (point-min) (point-max)))

(defun oz-to-coresyntax-region (start end)
  "Display the core syntax expansion of the current region."
  (interactive "r")
  (oz-directive-on-region start end "+core -codegen"))

(defun oz-to-coresyntax-line (arg)
  "Display the core syntax expansion of the current line.
With ARG, feed that many lines.  If ARG is negative, feed that many
preceding lines as well as the current line."
  (interactive "p")
  (let ((region (oz-line-region arg)))
    (oz-to-coresyntax-region (car region) (cdr region))))

(defun oz-to-coresyntax-paragraph (arg)
  "Display the core syntax expansion of the current paragraph.
If the point is exactly between two paragraphs, feed the preceding
paragraph.  With ARG, feed that many paragraphs.  If ARG is negative,
feed that many preceding paragraphs as well as the current paragraph."
  (interactive "p")
  (let ((region (oz-paragraph-region arg)))
    (oz-to-coresyntax-region (car region) (cdr region))))

(defun oz-to-emulatorcode-buffer ()
  "Display the emulator code for the current buffer."
  (interactive)
  (oz-to-emulatorcode-region (point-min) (point-max)))

(defun oz-to-emulatorcode-region (start end)
  "Display the emulator code for the current region."
  (interactive "r")
  (oz-directive-on-region
   start end "-core +codegen +outputcode -feedtoemulator"))

(defun oz-to-emulatorcode-line (arg)
  "Display the emulator code for the current line.
With ARG, feed that many lines.  If ARG is negative, feed that many
preceding lines as well as the current line."
  (interactive "p")
  (let ((region (oz-line-region arg)))
    (oz-to-emulatorcode-region (car region) (cdr region))))

(defun oz-to-emulatorcode-paragraph (arg)
  "Display the emulator code for the current paragraph.
If the point is exactly between two paragraphs, feed the preceding
paragraph.  With ARG, feed that many paragraphs.  If ARG is negative,
feed that many preceding paragraphs as well as the current paragraph."
  (interactive "p")
  (let ((region (oz-paragraph-region arg)))
    (oz-to-emulatorcode-region (car region) (cdr region))))

(defun oz-directive-on-region (start end switches)
  ;; Applies a directive to the region.
  (oz-send-string (concat "\\localSwitches\n"
                          "\\switch " switches "\n"
                          (oz-get-region start end))))

(defun oz-browse-buffer ()
  "Feed the current buffer to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Browse."
  (interactive)
  (oz-browse-region (point-min) (point-max)))

(defun oz-browse-region (start end)
  "Feed the current region to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Browse."
  (interactive "r")
  (let ((contents (oz-get-region start end)))
    (oz-send-string (concat "{Browse\n" contents "}")))
  (oz-zmacs-stuff))

(defun oz-browse-line (arg)
  "Feed the current line to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Browse.
With ARG, feed that many lines.  If ARG is negative, feed that many
preceding lines as well as the current line."
  (interactive "p")
  (let ((region (oz-line-region arg)))
    (oz-browse-region (car region) (cdr region))))

(defun oz-browse-paragraph (arg)
  "Feed the current paragraph to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Browse.
If the point is exactly between two paragraphs, feed the preceding
paragraph.  With ARG, feed that many paragraphs.  If ARG is negative,
feed that many preceding paragraphs as well as the current paragraph."
  (interactive "p")
  (let ((region (oz-paragraph-region arg)))
    (oz-browse-region (car region) (cdr region))))

(defun oz-show-buffer ()
  "Feed the current buffer to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Show."
  (interactive)
  (oz-show-region (point-min) (point-max)))

(defun oz-show-region (start end)
  "Feed the current region to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Show."
  (interactive "r")
  (let ((contents (oz-get-region start end)))
    (oz-send-string (concat "{Show\n" contents "}")))
  (oz-zmacs-stuff))

(defun oz-show-line (arg)
  "Feed the current line to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Show.
With ARG, feed that many lines.  If ARG is negative, feed that many
preceding lines as well as the current line."
  (interactive "p")
  (let ((region (oz-line-region arg)))
    (oz-show-region (car region) (cdr region))))

(defun oz-show-paragraph (arg)
  "Feed the current paragraph to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Show.
If the point is exactly between two paragraphs, feed the preceding
paragraph.  With ARG, feed that many paragraphs.  If ARG is negative,
feed that many preceding paragraphs as well as the current paragraph."
  (interactive "p")
  (let ((region (oz-paragraph-region arg)))
    (oz-show-region (car region) (cdr region))))

(defun oz-inspect-buffer ()
  "Feed the current buffer to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Inspect."
  (interactive)
  (oz-inspect-region (point-min) (point-max)))

(defun oz-inspect-region (start end)
  "Feed the current region to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Inspect."
  (interactive "r")
  (let ((contents (oz-get-region start end)))
    (oz-send-string (concat "{Inspect\n" contents "}")))
  (oz-zmacs-stuff))

(defun oz-inspect-line (arg)
  "Feed the current line to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Inspect.
With ARG, feed that many lines.  If ARG is negative, feed that many
preceding lines as well as the current line."
  (interactive "p")
  (let ((region (oz-line-region arg)))
    (oz-inspect-region (car region) (cdr region))))

(defun oz-inspect-paragraph (arg)
  "Feed the current paragraph to the Oz Compiler.
Assuming it to contain an expression, enclose it by an application
of the procedure Inspect.
If the point is exactly between two paragraphs, feed the preceding
paragraph.  With ARG, feed that many paragraphs.  If ARG is negative,
feed that many preceding paragraphs as well as the current paragraph."
  (interactive "p")
  (let ((region (oz-paragraph-region arg)))
    (oz-inspect-region (car region) (cdr region))))

;;}}}
;;{{{ Oz Debugger

(defun oz-debugger (arg)
  "Start the Oz debugger.
With ARG, stop it instead."
  (interactive "P")
  (oz-send-string (if arg "{Ozcar.close}" "{Ozcar.open}") t))

(defun oz-breakpoint-at-point (arg)
  "Set breakpoint at current line.
With ARG, delete it instead."
  (interactive "P")
  (oz-breakpoint arg))

(defun oz-breakpoint (flag)
  (save-excursion
    (beginning-of-line)
    (let ((line (1+ (count-lines 1 (point)))))
      (oz-send-string
       (concat "{Ozcar.object bpAt('"
               (or (buffer-file-name) (buffer-name))
               "' " (int-to-string line) (if flag " false" " true") ")}") t))))

;;}}}
;;{{{ Other Tools

(defun oz-profiler (arg)
  "Start the profiler.
With ARG, stop it instead."
  (interactive "P")
  (oz-send-string (if arg "{Profiler.close}" "{Profiler.open}") t))

(defun oz-open-panel ()
  "Feed `{Panel.open}' to the Oz Compiler."
  (interactive)
  (oz-send-string "{Panel.open}" t))

(defun oz-open-distribution-panel ()
  "Feed `{DistributionPanel.open}' to the Oz Compiler."
  (interactive)
  (oz-send-string "{DistributionPanel.open}" t))

(defun oz-open-compiler-panel ()
  "Feed `{New CompilerPanel.'class' init(OPI.compiler) _}' to the Oz Compiler."
  (interactive)
  (oz-send-string "{New CompilerPanel.'class' init(OPI.compiler) _}" t))

;;}}}
;;{{{ Misc Goodies

(defun oz-feed-file (file)
  "Feed a file to the Oz Compiler."
  (interactive "fFeed file: ")
  (oz-send-string (concat "\\insert '" file "'")))

;;}}}
;;{{{ The oz-bar (used by Compiler Panel, Debugger and Profiler)

(make-face 'bar-running)
(set-face-foreground 'bar-running "white")
(set-face-background 'bar-running (if oz-is-color "#a0a0a0" "black"))

(make-face 'bar-running-here)
(set-face-foreground 'bar-running-here "#707070")
(set-face-background 'bar-running-here (if oz-is-color "#d0d0d0" "white"))

(make-face 'bar-runnable)
(set-face-foreground 'bar-runnable "white")
(set-face-background 'bar-runnable (if oz-is-color "#7070c0" "black"))

(make-face 'bar-runnable-here)
(set-face-foreground 'bar-runnable-here "#5050a0")
(set-face-background 'bar-runnable-here (if oz-is-color "#d0d0d0" "white"))

(make-face 'bar-blocked)
(set-face-foreground 'bar-blocked "white")
(set-face-background 'bar-blocked (if oz-is-color "#d05050" "black"))

(make-face 'bar-blocked-here)
(set-face-foreground 'bar-blocked-here "#d05050")
(set-face-background 'bar-blocked-here (if oz-is-color "#d0d0d0" "white"))

(defvar oz-bar-overlay nil)
(defvar oz-bar-overlay-here nil)

(defun oz-bar (file line column state)
  ;; Display bar at given line, load file if necessary.
  (if (string-equal state "exit")
      (progn
        (oz-bar-remove)
        (call-interactively 'save-buffers-kill-emacs))
    (if (string-equal file "")
        (oz-bar-remove)
      (let* ((buffer (oz-find-buffer-or-file file t))
             (window (display-buffer buffer))
             start1 end1 start2 end2)
        (with-current-buffer buffer
          (save-excursion
            (save-restriction
              (widen)
              (goto-line line)
              (setq start1 (point))
              (save-excursion
                (forward-line 1)
                (setq end1 (point)))
              (if (> column 0)
                  (forward-char column))
              (if (and (>= column 0) (looking-at oz-token-pattern))
                  (setq start2 (match-beginning 0) end2 (match-end 0))
                (setq start2 start1 end2 start1))
              (or oz-bar-overlay
                  (cond (oz-gnu-emacs
                         (setq oz-bar-overlay (make-overlay start1 end1)
                               oz-bar-overlay-here (make-overlay start2 end2))
                         (overlay-put oz-bar-overlay 'priority 17)
                         (overlay-put oz-bar-overlay-here 'priority 18))
                        (oz-lucid-emacs
                         (setq oz-bar-overlay (make-extent start1 end1)
                               oz-bar-overlay-here (make-extent start2 end2))
                         (set-extent-priority oz-bar-overlay 17)
                         (set-extent-priority oz-bar-overlay-here 18))))
              (cond (oz-gnu-emacs
                     (move-overlay
                      oz-bar-overlay start1 end1 (current-buffer))
                     (move-overlay
                      oz-bar-overlay-here start2 end2 (current-buffer)))
                    (oz-lucid-emacs
                     (set-extent-endpoints
                      oz-bar-overlay start1 end1 (current-buffer))
                     (set-extent-endpoints
                      oz-bar-overlay-here start2 end2 (current-buffer))))
              (or (string-equal state "unchanged")
                  (oz-bar-configure state)))))
        (save-selected-window
          (let ((old-buffer (current-buffer)) old-pos)
            (select-window window)
            (set-buffer buffer)
            (setq old-pos (point))
            (if (or (< start1 (point-min)) (> start1 (point-max)))
                (widen))
            (if (not (pos-visible-in-window-p start1))
                (progn
                  (goto-char start1)
                  (recenter (/ (1- (window-height)) 2))))
            (if (pos-visible-in-window-p old-pos)
                (goto-char old-pos))
            (set-buffer old-buffer)))))))

(defun oz-bar-configure (state)
  ;; Change color of bar while not moving it.
  (let ((face
         (car (read-from-string (concat "bar-" state))))
        (face-here
         (car (read-from-string (concat "bar-" state "-here")))))
    (cond (oz-gnu-emacs
           (overlay-put oz-bar-overlay 'face face)
           (overlay-put oz-bar-overlay-here 'face face-here))
          (oz-lucid-emacs
           (set-extent-face oz-bar-overlay face)
           (set-extent-face oz-bar-overlay-here face-here)))))

(defun oz-bar-remove ()
  "Remove the bar marking an Oz source line."
  (interactive)
  (cond (oz-bar-overlay
         (cond (oz-gnu-emacs
                (delete-overlay oz-bar-overlay)
                (delete-overlay oz-bar-overlay-here))
               (oz-lucid-emacs
                (delete-extent oz-bar-overlay)
                (delete-extent oz-bar-overlay-here)))
         (setq oz-bar-overlay nil)
         (setq oz-bar-overlay-here nil))))

;;}}}
;;{{{ Testing Locally and Support for GDB

(defun oz-start-gdb-emulator ()
  ;; Run the Oz Emulator under gdb.
  ;; This is invoked when `*oz-gdb*' is non-nil as specified by the
  ;; current profile.
  ;; The directory containing FILE becomes the initial working directory
  ;; and source-file directory for gdb.  If you wish to change this, use
  ;; the gdb commands `cd DIR' and `directory'.
  (let ((old-buffer (current-buffer))
        (init-str (concat "set args -u " *oz-root-functor* "\n")))
    (cond ((get-buffer oz-emulator-buffer)
           (delete-windows-on oz-emulator-buffer)
           (kill-buffer oz-emulator-buffer)))
    (cond (oz-gnu-emacs
           (gdb (concat "gdb " *OZEMULATOR*)))
          (oz-lucid-emacs
           (gdb *OZEMULATOR*)))
    (setq oz-emulator-buffer (buffer-name (current-buffer)))
    (comint-send-string
     (get-buffer-process oz-emulator-buffer)
     init-str)
    (if (eq *oz-gdb* 'auto)
        (comint-send-string
         (get-buffer-process oz-emulator-buffer)
         "run\n"))
    (switch-to-buffer old-buffer)))

;;}}}
;;{{{ Application Development Support

(defvar oz-compile-history nil
  "History of commands used in oz-compile-file.")

(defun oz-compile-file (command)
  "Compile an Oz program non-interactively."
  (interactive (list (if (buffer-file-name)
                         (read-from-minibuffer "Oz compilation command: "
                                               *oz-compile-command* nil nil
                                               '(oz-compile-history . 1))
                       (error "Buffer has no file name"))))
  (setq *oz-compile-command* command)
  (let* ((file (buffer-file-name))
         (real-command (format *oz-compile-command* (or file ""))))
    (if (and file (buffer-modified-p)
             (y-or-n-p (format "Save buffer %s first? " (buffer-name))))
        (save-buffer))
    (compile-internal real-command "No more errors")))

(defvar oz-application-history nil
  "History of commands used in oz-debug-application.")

(defvar oz-application-name-pattern "\\`\\(.*\\)\\.ozg?\\'"
  "Regular expression matching a file name with an `.oz' or `.ozg' extension.
The first subexpression matches the file name without the extension.")

(defun oz-debug-application (command)
  "Invoke ozd."
  (interactive (list (if (oz-is-running)
                         (error "Only one Oz may be running")
                       (read-from-minibuffer "Oz application invocation: "
                                             *oz-application-command* nil nil
                                             '(oz-application-history . 1)))))
  (setq *oz-application-command* command)
  (let* ((file (buffer-file-name))
         (app (if file
                  (if (string-match oz-application-name-pattern file)
                      (oz-match-string 1 file))))
         (real-command (concat "ozd -E --opi -- "
                               (format *oz-application-command* (or app "")))))
    (oz-make-comint "/bin/sh" "-c" real-command)
    (oz-prepare-emulator-buffer 'oz-filter t)))

;;}}}
;;{{{ Oz-Machine Mode

(defconst ozm-keywords-matcher
  (concat "\\<\\("
          "true\\|false\\|unit" "\\|"
          "pos\\|pid\\|ht\\|onScalar\\|onRecord\\|cmi"
          "\\)\\>"))

(defconst ozm-instr-matcher-1
  (concat
   "\t\\("
   (mapconcat
    'identity
    '("move" "moveMove"
      "allocateL" "createVariable" "createVariableMove" "putConstant"
      "putList" "putRecord" "setConstant" "setProcedureRef" "setValue"
      "setVariable" "setVoid" "getNumber" "getLiteral" "getList"
      "getListValVar" "getListVarVar" "getRecord" "unifyNumber" "unifyLiteral"
      "unifyValue" "unifyVariable" "unifyValVar" "unifyVoid" "unify" "branch"
      "callBI" "inlinePlus1?" "inlineMinus1?" "inlineDot" "inlineAt"
      "inlineAssign" "callGlobal" "callMethod" "call" "consCall" "deconsCall"
      "tailCall" "tailConsCall" "tailDeconsCall" "callProcedureRef"
      "callConstant" "sendMsg" "tailSendMsg" "exHandler" "testLiteral"
      "testNumber" "testRecord" "testList" "testBool" "testBI" "testLT"
      "testLE" "match" "getVariable" "getVarVar" "getVoid" "lockThread"
      "getSelf" "setSelf" "debugEntry" "debugExit" "globalVarname"
      "localVarname" "clear") "\\|")
   "\\)("))

(defconst ozm-instr-matcher-2
  (concat
   "\t\\("
   (mapconcat
    'identity
    '("allocateL[1-9]" "allocateL10" "deAllocateL" "deAllocateL[1-9]"
      "deAllocateL10" "return" "popEx" "skip" "profileProc")
    "\\|")
   "\\)$"))

(defconst ozm-definition-matcher
  "\t\\(definition\\|definitionCopy\\|endDefinition\\)(")

(defconst ozm-register-matcher
  "\\<\\(x\\|y\\|g\\)([0-9]+)")

(defconst ozm-label-matcher
  "^lbl(\\([A-Za-z0-9_]+\\|'[^'\n]*'\\))")

(defconst ozm-name-matcher
  "<N: [^>]+>")

(defconst ozm-builtin-name-matcher
  "\t\\(callBI\\|testBI\\)(\\([A-Za-z0-9_]+\\|'[^'\n]*'\\)")

(defconst ozm-font-lock-keywords-1
  (list (cons ozm-keywords-matcher 1)
        (list ozm-instr-matcher-1
              '(1 font-lock-keyword-face))
        (list ozm-instr-matcher-2
              '(1 font-lock-keyword-face))
        (list ozm-definition-matcher
              '(1 font-lock-function-name-face))
        (cons ozm-name-matcher 'font-lock-string-face)))

(defconst ozm-font-lock-keywords ozm-font-lock-keywords-1)

(defconst ozm-font-lock-keywords-2
  (append (list (list ozm-register-matcher
                      '(1 font-lock-type-face))
                (cons ozm-label-matcher 'font-lock-reference-face)
                (list ozm-builtin-name-matcher
                      '(2 font-lock-variable-name-face)))
          ozm-font-lock-keywords-1))

(defun ozm-set-font-lock-defaults ()
  (set (make-local-variable 'font-lock-defaults)
       '((ozm-font-lock-keywords ozm-font-lock-keywords-1
          ozm-font-lock-keywords-2)
         nil nil nil beginning-of-line)))

(defun ozm-mode ()
  "Major mode for displaying Oz machine code.

Commands:
\\{oz-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (use-local-map oz-mode-map)
  (setq major-mode 'ozm-mode)
  (setq mode-name "Oz-Machine")
  (oz-mode-variables)
  (ozm-set-font-lock-defaults)
  (if (and oz-want-font-lock window-system)
      (font-lock-mode 1)))

;;}}}

(provide 'mozart)

;;; Local Variables: ***
;;; mode: emacs-lisp ***
;;; byte-compile-dynamic-docstrings: nil ***
;;; byte-compile-compatibility: t ***
;;; End: ***
