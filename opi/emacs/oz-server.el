;;;
;;; Authors:
;;;   Denys Duchier <duchier@ps.uni-sb.de>
;;;
;;; Contributors:
;;;
;;; Copyright:
;;;   Denys Duchier, 2000
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

;;; ==================================================================
;;; This file implements a more principled and uniform framework to
;;; allow emacs and the Oz process to interact.  The idea is to create
;;; a socket connection on which the two processes can exchange
;;; messages.  By design, the set of message types which can be
;;; exchanged is indefinitely extensible.
;;; ==================================================================

(provide 'oz-server)

(defconst oz-server-name "*Oz Server*"
  "name of the server process")

(defvar oz-server-process nil
  "the server process itself")

(defun oz-server-open (host port)
  "open a server connection to the Oz process running on
HOST and waiting at PORT"
  (let ((process (open-network-stream
                  oz-server-name nil host port)))
    (setq oz-server-process process)
    (set-process-filter   process 'oz-server-filter)
    (set-process-sentinel process 'oz-server-sentinel)))

;;; ==================================================================
;;; A message consists of a finite sequence of argument strings.  The
;;; end of this sequence is indicated by ^B (ie \002).  Each argument
;;; string is terminated by ^A (ie \001).  In order to permit argument
;;; strings to contain ^A and ^B characters we need to encode them: we
;;; use ^C (ie \003) as a quoting character and add 100 to the quoted
;;; character.  Thus ^A is encoded as ^Ce, ^B as ^Cf, and ^C as ^Cg.
;;; ==================================================================

(defconst oz-server-eoa "\001" "end of argument character")
(defconst oz-server-eom "\002" "end of message character")
(defconst oz-server-quo "\003" "quoting character")

(defconst oz-server-quo-skip (concat "^" oz-server-quo)
  "anything but a quoting character")

(defconst oz-server-all-skip
  (concat "^" oz-server-eoa oz-server-eom oz-server-quo)
  "anything but an `end of argument', `end of message',
or `quoting character'")

(defvar oz-server-buffered-input ""
  "accumulated partial message")

;;; ==================================================================
;;; the oz-server process does not have an associated buffer, only a
;;; a filter and a sentinel.  the filter accumulates a partial
;;; message until it finds the `end of message' character.  At that
;;; point it splits the message into arguments, decodes them and
;;; processes the message.
;;; ==================================================================

(defun oz-server-filter (process input)
  (let ((i (string-match oz-server-eom input)))
    (if i
        (let ((prefix (substring input 0 i))
              (suffix (substring input (1+ i)))
              args)
          (setq args (concat oz-server-buffered-input prefix)
                oz-server-buffered-input nil)
          (oz-server-process-message
           (mapcar 'oz-server-unescape (split-string args oz-server-eoa)))
          ;; process the remainder in case it contains EOM
          (oz-server-filter process suffix))
      (setq oz-server-buffered-input
            (concat oz-server-buffered-input input)))))

(defconst oz-server-temp "*Oz Server Temp*")

(defun oz-server-unescape (string)
  "decode STRING"
  (let ((b (get-buffer-create oz-server-temp)))
    (save-excursion
      (save-restriction
        (set-buffer b)
        (widen)
        (erase-buffer)
        (insert string)
        (goto-char (point-min))
        (let ((redo t))
          (while redo
            (skip-chars-forward oz-server-quo-skip)
            (if (eobp)
                (setq redo nil)
              (let ((c (- (char-after (1+ (point))) 100)))
                (delete-char 2)
                (insert c)))))
        (buffer-string)))))

(defun oz-server-escape (string)
  "encode STRING"
  (let ((b (get-buffer-create oz-server-temp)))
    (save-excursion
      (save-restriction
        (set-buffer b)
        (widen)
        (erase-buffer)
        (insert string)
        (goto-char (point-min))
        (let ((redo t))
          (while redo
            (skip-chars-forward oz-server-all-skip)
            (if (eobp)
                (setq redo nil)
              (let ((c (+ (char-after (point)) 100)))
                (delete-char 1)
                (insert oz-server-quo c)))))
        (buffer-string)))))

;;; ==================================================================
;;; the sentinel simply resets the oz-server-process variable to nil
;;; when the connection to the Oz process is closed.
;;; ==================================================================

(defun oz-server-sentinel (process status)
  (setq oz-server-process nil))

;;; ==================================================================
;;; a message from the Oz process has one of the following forms:
;;;
;;;     reply      ID  ARG1 ... ARGn
;;;     replyError ID  ARG1 ... ARGn
;;;     event      TAG ARG1 ... ARGn
;;;
;;; every query sent to the Oz process is given a unique ID (an
;;; integer).  When the reply comes back from the Oz process (of
;;; course asynchronously), it carries the ID with it so that the
;;; reply can be matched with the corresponding query.
;;;
;;;     reply      ID  ARG1 ... ARGn
;;;
;;; this is a successful reply to request ID.  the values returned are
;;; given by the strings ARG1 ... ARGn.
;;;
;;;     replyError ID  ARG1 ... ARGn
;;;
;;; this is an error reply to request ID.  When the Oz process tried
;;; to handle this request, an exception was raised.  Typically, there
;;; is only 1 ARG returned and it contains the formatted error.
;;;
;;;     event      TAG ARG1 ... ARGn
;;;
;;; the Oz process may also asynchronously send "events" to emacs.
;;; What kind of event is identified by TAG: this is used to find the
;;; appropriate handler in `oz-server-event-alist'.  The ARGs give
;;; further information and depend on the kind of event.
;;; ==================================================================

(defun oz-server-process-message (args)
  (let ((tag (intern (car args))))
    (cond ((eq tag 'reply)      (oz-server-process-reply (cdr args)))
          ((eq tag 'replyError) (oz-server-process-replyError (cdr args)))
          ((eq tag 'event)      (oz-server-process-event (cdr args)))
          (t (error "unknown tag `%s'" tag)))))

;;; ==================================================================
;;; surprisingly enough, elisp does not seem to offer a complete API
;;; for associative maps.  Here is mine for an alist based
;;; representation.  An alist has the form
;;;     (ALIST (KEY1 . VAL1) ... (KEYn . VALn))
;;; the advantage of having the CAR be the symbol ALIST is that we can
;;; destructively modify the CDR: this makes it easier to add a new
;;; pair (at the front), and to delete the first pair.
;;; ==================================================================

(defun oz-server-alist-make ()
  "create a new alist"
  (list 'ALIST))

(defun oz-server-alist-get (alist key)
  "return the value associated with KEY in ALIST, or nil
if KEY is not found"
  (cdr (assq key (cdr alist))))

(defun oz-server-alist-put (alist key val)
  "set to VAL the value associated with KEY in ALIST"
  (let ((e (assq key (cdr alist))))
    (if e (setcdr e val)
      (setcdr alist (cons (cons key val) (cdr alist))))))

(defun oz-server-alist-del (alist key)
  "delete the entry for KEY in ALIST. do nothing if KEY is
not found in ALIST"
  (let ((prev alist)
        (curr (cdr alist)))
    (while curr
      (if (eq (caar curr) key)
          (progn
            (setcdr prev (cdr curr))
            (setq curr nil))
        (setq prev curr curr (cdr curr))))))

;;; ==================================================================
;;; when sending a query to the Oz process, we must register a
;;; callback to process the reply when it comes back (asynchronously).
;;; When registering a callback, we provide FUNCTION and DATA (where
;;; DATA serves the purpose of a closure).  When the reply comes back
;;; the callback is invoked as follows:
;;;
;;;     (FUNCTION ERRFLAG ARGS DATA)
;;;
;;; where ERRFLAG is `t' if an error occurred, and `nil' otherwise,
;;; i.e. if the reply is either a `reply' or `replyError'. ARGS are
;;; the argument strings in the reply or replyError.
;;; ==================================================================

(defvar oz-server-callback-alist (oz-server-alist-make)
  "maps ID of request to callback, i.e. to a pair (FUNCTION . DATA)")

;;; ==================================================================
;;; events come in completely asynchronously, not in response to a
;;; query, and are represented by messages of the form:
;;;
;;;     event TAG ARG1 ... ARGn
;;;
;;; We use TAG to retrieve the appropriate HANDLER from
;;; `oz-server-handler-alist' and it is called as follows:
;;;
;;;     (HANDLER TAG (list ARG1 ... ARGn))
;;;
;;; if there is no corresponding handler, the event is simply ignored.
;;; ==================================================================

(defvar oz-server-handler-alist nil
  "alist with entries of the form (TAG . HANDLER)")

(defun oz-server-process-reply-generic (args errflag)
  (let* ((id (string-to-number (car args)))
         (vals (cdr args))
         (callback (oz-server-alist-get oz-server-callback-alist id)))
    (if callback
        (progn
          (oz-server-alist-del oz-server-callback-alist id)
          (condition-case nil
              (funcall (car callback) errflag vals (cdr callback))
            (error nil))))))

(defun oz-server-process-reply (args)
  (oz-server-process-reply-generic args nil))

(defun oz-server-process-replyError (args)
  (oz-server-process-reply-generic args t))

(defconst oz-server-errors "*Oz Server Errors*"
  "name of buffer in which to display errors")

;;; ==================================================================
;;; when replyError comes back what should the callback do?  One
;;; possibility is to call `oz-server-display-error' to display the
;;; error message that it got back.
;;; ==================================================================

(defun oz-server-display-error (MSG)
  "display error message in an error buffer"
  (let ((b (get-buffer-create oz-server-errors)))
    (save-excursion
      (save-restriction
        (set-buffer b)
        (widen)
        (let ((p (point-max)) w)
          (goto-char p)
          (insert MSG ?\n ?\n)
          (setq w (display-buffer b))
          (set-window-start w p))))))

;;; ==================================================================
;;; when an event comes in, finds its handler if any and invoke it to
;;; take appropriate action.  If there is no handler, the event is
;;; simply ignored.
;;; ==================================================================

(defun oz-server-process-event (args)
  (let* ((tag (intern (car args)))
         (handler (cdr (assq tag oz-server-handler-alist))))
    (if handler
        (condition-case nil
            (funcall handler tag (cdr args))
          (error nil)))))

;;; ==================================================================
;;; since communication between emacs and the Oz process is not
;;; synchronous, we use an ID mechanism to associate each query with
;;; the corresponding reply.
;;; ==================================================================

(defvar oz-server-query-count 0
  "monotonically increasing counter used to generate unique IDs")

;;; ==================================================================
;;; whenever we send a query to the Oz process, we must register a
;;; callback to process the reply.
;;; ==================================================================

(defun oz-server-query (args callback data)
  "send a query ARGS, a list of strings, to the Oz process, and
register CALLBACK and DATA to process the reply"
  (let* ((id oz-server-query-count)
         (msg (mapcar 'oz-server-escape
                      (cons (int-to-string id) args))))
    (setq oz-server-query-count (1+ id))
    (oz-server-alist-put oz-server-callback-alist id
                         (cons callback data))
    (while msg
      (process-send-string
       oz-server-process (concat (car msg) oz-server-eoa))
      (setq msg (cdr msg)))
    (process-send-string
     oz-server-process oz-server-eom)))

;;; ==================================================================
;;; sometimes we want to query synchronously, for example when we want
;;; to write a function whose value requires an answer from the Oz
;;; process.  This implemented using the same mechanism as above and
;;; by polling to see if the reply has arrived.
;;; ==================================================================

(defvar oz-server-synchronous-polling nil
  "a flag that is t while waiting for the reply: the synchronous
callback sets it to nil")

(defvar oz-server-synchronous-reply nil
  "the synchronous callback sets it to (ERRFLAG ARG1 ... ARGn)")

(defun oz-server-synchronous-callback (errflag vals data)
  ;; store the reply and set the polling flag to nil
  (setq oz-server-synchronous-polling nil
        oz-server-synchronous-reply (cons errflag vals)))

(defconst oz-server-polling-delay 0.05
  "delay between polling attempts")

(defun oz-server-query-synchronously (args)
  "send the query consisting of the list of strings ARGS to the
Oz process, wait for the reply and return the correposning list
of strings.  Raise an 'oz-server-query exception in case we get
back a replyError."
  (unwind-protect
      (progn
        (setq oz-server-synchronous-polling t)
        (oz-server-query args 'oz-server-synchronous-callback nil)
        (while oz-server-synchronous-polling
          (sit-for oz-server-polling-delay))
        (let ((errflag (car oz-server-synchronous-reply))
              (vals    (cdr oz-server-synchronous-reply)))
          (if errflag
              (signal 'oz-server-query vals)
            vals)))
    (setq oz-server-synchronous-polling nil
          oz-server-synchronous-reply   nil)))
