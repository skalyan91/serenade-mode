(require 'serenade-editor-state)
(require 'serenade-buffer)

(defun serenade--handle-message (message) 
  (let* ((callback (ht-get* message "data" "callback")) 
         (command-vector (ht-get* message "data" "response" "execute" "commandsList")) 
         (command-list (append command-vector nil))) 
    (dolist (command command-list ) 
      (serenade--handle-command command message callback))))

(defun serenade--handle-command (command message callback) 
  (serenade--set-serenade-buffer) 
  (let* ((type (ht-get*  command "type")) 
         (limited (ht-get* command "limited" ))) 
    (cond ((equal type "COMMAND_TYPE_EVALUATE_IN_PLUGIN") 
           (serenade--evaluate-in-plugin command))) 
    (if serenade-buffer (cond ((equal type "COMMAND_TYPE_GET_EDITOR_STATE") 
                               (message "getting state") 
                               (serenade--get-editor-state callback limited)) 
                              ((equal type "COMMAND_TYPE_DIFF") 
                               (progn (serenade--diff command) 
                                      (serenade--send-completed))) 
                              ((equal type "COMMAND_TYPE_SELECT") 
                               (serenade-select-region (+ 1 (ht-get* command "cursor")) 
                                                            (+ 1 (ht-get* command "cursorEnd")))) 
                              (t (serenade--run-default-command command))))))

(defun serenade--diff (command) 
  (serenade--update-buffer (ht-get command "source") 
                           (+(ht-get command "cursor") 1)))

(defun serenade--evaluate-in-plugin (command) 
  (let* ((command-text (ht-get* command "text")) 
         (command-type (ht-get* command "type"))) 
    (eval (car (read-from-string command-text)))))

(defun serenade--run-default-command (command))

(defun serenade--send-completed () 
  (let* ((response (ht("message" "complete") 
                      ("data" nil))) 
         (response-json (json-serialize response))) 
    (websocket-send-text serenade--websocket response-json)))

(provide 'serenade-handler)
