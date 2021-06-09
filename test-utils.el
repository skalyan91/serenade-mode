(defun spy-on-fn (sym) 
  (setf (symbol-function sym) 
        (lambda ()
          ;; (print "calling spy")
          )) 
  (spy-on sym))
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

(provide 'test-utils)
