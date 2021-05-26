(defun serenade-handle-get-editor-state (callback limited) 
  (let* ((filename (-last-item (s-split "/" (buffer-file-name)))) 
         (buffer-data (ht ("source" (buffer-string)) 
                          ("cursor" (- (point) 1)) 
                          ("filename" filename))) 
         (response (ht("message" "callback") 
                      ("data" (ht ("callback" callback) 
                                  ("data" (ht ("message" "editorState") 
                                              ("data" buffer-data))))))) 
         (response-json (json-serialize response))) 
    (message "sending state") 
    (message response-json) 
    (websocket-send-text s-websocket response-json)))
