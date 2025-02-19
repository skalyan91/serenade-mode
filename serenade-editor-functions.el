
(defvar serenade-evil nil 
  "If true, use evil commands where possible for default commands")

(defun serenade--get-editor-state () 
  "The default get editor state function. It gets the filename source and cursor for the buffer."
  (let* ((source 
          (buffer-substring-no-properties 
           (point-min) 
           (point-max))) 
         (filename  (if (buffer-file-name) 
                        (-last-item (s-split "/" (buffer-file-name))) "")) 
         (cursor  (- (point) 1))) 
    (list filename source cursor)))

(defun serenade--diff (source cursor) 
  "The default diff function. This function replaces the current buffer contents and cursor with the provided SOURCE and CURSOR position from the diff command."
  (if source (let ((tmp-buf (generate-new-buffer " *serenade-temp*"))) 
               (with-current-buffer tmp-buf (insert source)) 
               (replace-buffer-contents tmp-buf) 
               (kill-buffer tmp-buf))) 
  (goto-char cursor))

(defun serenade--read-only-diff (source cursor) 
  "A diff function for read-only buffers. This function replaces the current buffer cursor but not the source."
  (goto-char cursor))

(defun serenade--minibuffer-diff (source cursor) 
  "A diff function for read-only buffers. This function replaces the current buffer cursor but not the source.")

(defun serenade--select-target (min max) 
  (if serenade-evil (progn (goto-char min) 
                           (evil-visual-state ) 
                           (goto-char max)) 
    (progn (goto-char  min ) 
           (push-mark (+ 1 max)) 
           (setq mark-active t))))

(defun serenade--cut-selection () 
  (if serenade-evil (execute-kbd-macro (kbd "x" )) 
    (kill-region (region-beginning) 
                 (region-end)) 
    (setq mark-active nil)))

(defun serenade--copy-selection () 
  (if serenade-evil (progn (execute-kbd-macro (kbd "y")) 
                           (evil-normal-state)) 
    (progn (kill-ring-save nil nil t ))))

(defun serenade--undo () 
  (if serenade-evil (evil-undo 1) 
    (undo)))

(defun serenade--redo ()
  ;;TODO: does not return cursor position precisely
  (if serenade-evil (evil-redo 1) 
    (redo)))

(defun serenade--switch-tab (index) 
  (winum-select-window-by-number index))

(defun serenade--get-buffer-by-regex (fragment) 
  "search for buffer by name and switch to it"
  (let* ((matching-buffers (-filter (lambda (elt) 
                                      (s-contains? fragment (buffer-name elt) t)) 
                                    (buffer-list)))) matching-buffers))

(defun serenade--open-file (fragment) 
  (let* ((b (serenade--get-buffer-by-regex fragment))) 
    (switch-to-buffer (first b))))

(defun serenade--set-source (source) 
  "This function replaces the current buffer contents and cursor with the provided SOURCE and CURSOR position from the diff command."
  (let ((tmp-buf (generate-new-buffer " *serenade-temp*"))) 
    (with-current-buffer tmp-buf (insert source)) 
    (replace-buffer-contents tmp-buf) 
    (kill-buffer tmp-buf)))

(provide 'serenade-editor-functions)
