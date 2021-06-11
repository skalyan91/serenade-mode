(setq lexical-binding t )

(defun bc/set-spy (sym) 
  (lexical-let ((old-value (symbol-function sym)) 
                (sym-name (symbol-name sym)) 
                (revert-sym   (intern (concat "bc/revert-" (symbol-name sym))))) 
    (setf (symbol-function (intern-soft sym-name)) 
          '(lambda ()
             ;; (debug)
             (message "spy"))) 
    (spy-on sym) 
    (setf (symbol-function revert-sym) 
          (lambda () 
            (message sym-name) 
            (setf (symbol-function (intern-soft sym-name)) old-value )))))

;; (defun bc/test ()
;; (message "hello"))
;; (setq jr/hello "abc")
;; (bc/set-spy 'bc/test)
;; (bc/test)
;; (bc/revert-bc/test)
;; (bc/test)

(defun bc/set-var (sym new-val) 
  (lexical-let ((old-value (symbol-value sym)) 
                (sym-name (symbol-name sym)) 
                (revert-sym   (intern (concat "bc/revert-" (symbol-name sym))))) 
    (set (intern-soft sym-name) new-val ) 
    (setf (symbol-function revert-sym) 
          (lambda ()
            ;; (message old-value)
            ;; (debug)
            ;; (debug)
            (set (intern-soft sym-name) old-value )))))

;; (setq bc/test2 "a" )
;; (message bc/test2)
;; (bc/set-var 'bc/test2 "b")
;; (message bc/test2)
;; (bc/revert-bc/test2)
;; (message bc/test2)
;; (debug)

(defun spy-on-fn-1 (sym) 
  (setf (symbol-function sym) 
        (lambda (a)
          ;; (print "calling spy")
          )) 
  (spy-on sym))

(defun spy-on-fn-2 (sym) 
  (setf (symbol-function sym) 
        (lambda (a b)
          ;; (print "calling spy")
          )) 
  (spy-on sym))
(defun spy-on-fn-3 (sym) 
  (setf (symbol-function sym) 
        (lambda (a b c)
          ;; (print "calling spy")
          )) 
  (spy-on sym))

(defun create-test-buffer (name text) 
  (switch-to-buffer (get-buffer-create name)) 
  (setq buffer-file-name name) 
  (insert text))

(defun reset-maps () 
  (setf (symbol-value 'serenade-mode-maps ) 
        (ht("global" (ht)))))

(defmacro async-with-timeout (timeout &rest body) 
  `(progn 
     (setq jr-async-returned nil)
     ,@body (with-timeout (,timeout) 
              (while (not jr-async-returned) 
                (sleep-for 0.1)))))

(defun load-json-commands () 
  (with-temp-buffer (insert-file-contents "test/commands.json") 
                    (buffer-string)))

(defun load-json-responses () 
  (with-temp-buffer (insert-file-contents "test/responses.json") 
                    (buffer-string)))

(defun load-request (name) 
  (ht-get* (json-parse-string (load-json-commands)) name))

(defun load-response (name) 
  (json-serialize (ht-get* (json-parse-string (load-json-responses)) name)))

(defmacro measure-time 
    (&rest 
     body)
  "Measure and return the running time of the code block."
  (declare (indent defun)) 
  (let ((start (make-symbol "start"))) 
    `(let ((,start (float-time))) ,@body (- (float-time) ,start))))

(defun extract-json (data) 
  (message (s-replace "\\" "" (s-replace "\\n" "" (json-serialize data)))) 
  (message (s-replace "\\" "" (json-serialize data))))

(provide 'test-utils)
