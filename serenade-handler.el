

(defun serenade--handle-message (message) 
  (let* ((callback (ht-get* message "data" "callback")) 
         (command-vector (ht-get* message "data" "response" "execute" "commandsList")) 
         (command-list (append command-vector nil))) 
    (dolist (command command-list ) 
      (serenade--handle-command command message callback))))

(defun serenade--handle-command (command message callback) 
  (let* ((type (ht-get*  command "type")) 
         (limited (ht-get* command "limited" ))) 
    (cond ((equal type "COMMAND_TYPE_GET_EDITOR_STATE") 
           (if (not (eq nil (buffer-file-name))) 
               (serenade--get-editor-state callback limited))) 
          ((equal type '"COMMAND_TYPE_DIFF") 
           (serenade--diff command) 
           (serenade--send-completed)) 
          ((equal type "COMMAND_TYPE_EVALUATE_IN_PLUGIN") 
           (serenade--evaluate-in-plugin command)))))

(defun serenade--diff (command) 
  (serenade--update-buffer (ht-get command "source") 
                           (+(ht-get command "cursor") 1)))

(defun serenade--evaluate-in-plugin (command) 
  (let* ((command-text (ht-get* message-command "text")) 
         (command-type (ht-get* message-command "type"))) 
    (eval (car (read-from-string command-text)))))

(defun serenade--send-completed () 
  (let* ((response (ht("message" "complete") 
                      ("data" nil))) 
         (response-json (json-serialize response))) 
    (websocket-send-text serenade--websocket response-json)))

(provide 'serenade-handler)
