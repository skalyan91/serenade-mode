(defcustom serenade-mode-filetypes 
  '("js" "py" "c" "h" "cpp" "cc" "cxx" "c++" "hpp" "hh" "hxx" "h++""cs""css" "scss""dart" "go"
    "html" "vue" "svelte" "java" "js" "jsx" "jsx" "js""jsx" "js" "kt" "py" "rb" "rs" "scss" "sh"
    "bash" "ts" "tsx" "tsx" "ts""vue" "html" "el")
  "The filetypes that can be used as serenade buffers, which are buffers subject to the diff operation.")

(defvar serenade-mode-config-map (ht ) 
  "The list of mode configurations.")

(setq serenade-active-mode-configuration nil )

(defun serenade--initialize-mode-config-map ()
  ;; This function clears the SERENADE-MODE-CONFIG-MAP and sets only the global (default) mode config
  ;; (serenade--clear-mode-config-map)
  (serenade--configure-mode :mode 'global ))

(defun serenade--clear-mode-config-map () 
  (setq serenade-mode-config-map (ht ) ))

(defun serenade--set-active-mode-configuration ()
  ;; Set the active mode configuration based on the major-mode. If none is found, use the global default..
  (let* ((mode-name (symbol-name major-mode )) 
         (active-config  (ht-get* serenade-mode-config-map mode-name))) 
    (setq serenade-active-mode-configuration (or active-config 
                                                 (ht-get* serenade-mode-config-map "global")))))

(cl-defstruct 
    serenade-mode-configuration
  mode
  get-editor-state
  diff
  post-edit
  pre-edit)

(cl-defun 
    serenade--configure-mode 
    (&optional 
     &keys
     mode
     get-editor-state
     diff
     post-edit
     pre-edit) 

  ;; -A get-editor-state function accepts two parameters, callback and limited, and returns a list of items of form  '(CALLBACK LIMITED FILENAME SOURCE CURSOR), where filename is the name of the file, source is the contents for serenade to change, and cursor is the current location of the cursor)
  ;; -A diff function accepting two parameters, source and cursor, which updates the buffer with the new source and cursor position.
  (let* ((config  (make-serenade-mode-configuration ;;
                   :mode (or mode 
                             nil) 
                   :get-editor-state (or get-editor-state 
                                         'serenade--get-editor-state) 
                   :diff (or diff 
                             'serenade--diff) 
                   :post-edit (or post-edit 
                                  nil) 
                   :pre-edit (or pre-edit 
                                 nil)))) 
    (ht-set serenade-mode-config-map (symbol-name mode) config)))

(defun serenade--set-serenade-buffer ()
  ;; Determines if the current buffers file extension is a valid member of SERENADE-MODE-FILE-TYPES. If it is set SERENADE-BUFFER to the current buffer, otherwise set it to nil.
  (if (and (buffer-file-name) 
           (file-name-extension (buffer-file-name))) 
      (let* ((ext (file-name-extension (buffer-file-name)))) 
        (if (member ext serenade-mode-filetypes) 
            (setq serenade-buffer (current-buffer) ) 
          (setq serenade-buffer nil ))) 
    (setq serenade-buffer nil )))
;; (serenade--configure-mode :mode 'global )
;; (serenade--initialize-mode-config-map)

(provide 'serenade-modes)
