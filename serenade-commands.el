(require 'ht)

(defvar serenade-speech-maps (ht("global" (ht)) ) 
  "hashtable of Serenade voice maps")

(defvar serenade--add-builtin-global-defaults t 
  "this variable determines whether the builtin global defaults are added when the mode loads")

(defvar serenade--add-generated-global-defaults t 
  "this variable determines whether the generated global defaults are added when the mode loads")

(defun serenade--initialize-speech-maps () 
  "This function clears the SERENADE-SPEECH-MAPS and sets them according to the default binding."
  (serenade--clear-speech-maps) 
  (if serenade--add-builtin-global-defaults (serenade--add-builtin-global-defaults)) 
  (if serenade--add-generated-global-defaults (serenade--add-generated-global-defaults)) 
  (run-hooks 'serenade-speech-maps-hook))

(defun serenade--clear-speech-maps () 
  (setq serenade-speech-maps (ht("global" (ht)) ) ) 
  (if serenade--helm-M-x-active (serenade--clear-helm-M-x-map)))

(defun serenade--get-global-map () 
  (ht-get serenade-speech-maps "global"))

(defun serenade--add-builtin-global-defaults () 
  (serenade-global-set-speech serenade--builtin-global-defaults))

(defun serenade--add-generated-global-defaults () 
  (serenade-global-set-speech serenade--generated-global-defaults))

(cl-defun 
    serenade-global-set-speech
    (speech &optional command )
  "Convenience function for adding speech bindings to the global serenade speech map. Possible inputs are an association list of speech-command bindings, a single command from which the asociated speech is automatically generated, or a pair of SPEECH and COMMAND."
  (if (and (listp speech)) 
      (dolist (item speech ) 
        (serenade-global-set-speech (car item) 
                                    (cdr item)))) 
  (serenade-define-speech 'global speech command))

(defun serenade-auto-define-speech (mode command-or-list) 
  (if (listp command-or-list) 
      (dolist (command command-or-list ) 
        (serenade-auto-define-speech mode command)) 
    (let* ((split-command  (s-replace  "-" " " (symbol-name command-or-list)))) 
      (serenade-define-speech mode split-command command-or-list))))

(cl-defun 
    serenade-define-speech
    (mode speech &optional command)
  "this function associates speech pattern SPEECH with an Elisp function COMMAND for the symbol MODE. If the speech-map provided by MODE does not exist a speech-map is created. If mode is the special symbol 'global then the binding is created for the global speech map. If a previous binding exists for the speech pattern it is overwritten."
  (if (listp speech) 
      (dolist (item speech ) 
        (serenade-define-speech mode (car item) 
                                (cdr item))) 
    (let* ((name (symbol-name mode)) 
           (voice-map (ht-get serenade-speech-maps name ))) 
      (if (string-equal name "global") 
          (serenade--set-speech-bindings "global" speech command) 
        (progn (if (not voice-map) 
                   (ht-set serenade-speech-maps name (ht))) 
               (serenade--set-speech-bindings name speech command))) 
      (if serenade--helm-M-x-active (serenade--update-helm-M-x-map speech command)))))

(defun serenade--sort-args (args) 
  (-map '(lambda (item) 
           (s-trim (s-replace-regexp "\\\(%[0-9]+\\\)" "" item))) 
        (-sort '(lambda (arg1 arg2) 
                  (let* ((n1 (string-to-number (car (nth 0 (s-match-strings-all "\\\([0-9]+\\\)"
                                                                                arg1)))))
                         (n2 (string-to-number (car (nth 0 (s-match-strings-all "\\\([0-9]+\\\)"
                                                                                arg2))))))
                    (< n1 n2))) ;;
               args)))

(defun serenade--set-speech-bindings (map-name pattern command) 
  "Add the speech binding, removing any argument transformers in the pattern and extraneous spaces in arguments and around the pattern. If there are arguments, sort based on order transformer if present. If there are no args arguments is set to nil."
  (let* ((clean-pattern (s-trim (s-replace " >" ">" (s-replace "< " "<" (s-replace-regexp "%[0-9]+"
                                                                                          ""
                                                                                          pattern)))))
         (args (-flatten (-map 'cdr (s-match-strings-all "<\\(.+?\\\)>" pattern)))) 
         (maybe-sorted-args (if args (if (s-matches-p "%[0-9]" (first args)) ;;
                                         (serenade--sort-args args)          ;;
                                       args  ) nil))) 
    (ht-set (ht-get serenade-speech-maps name ) clean-pattern (ht ("command" command) 
                                                                  ("arguments" maybe-sorted-args)))))

(defun serenade--find-voice-binding (speech) 
  (or (serenade--find-in-active-minor-maps speech) 
      (serenade--find-in-active-major-map speech) 
      (serenade--find-in-global-map speech)))

(defun serenade--find-in-active-minor-maps (speech) 
  "search speech map applicable to the current minor-mode-map-alist. If any contain the speech patterns SPEECH return the command for the speech." 
  (catch 'result 
    (mapc (lambda (mode-and-map) 
            (if (and (boundp (car mode-and-map)) 
                     (symbol-value (car mode-and-map))) 
                (if-let* ((mode (symbol-name (car mode-and-map))) 
                          (voice-map (ht-get* serenade-speech-maps mode)) 
                          (command (ht-get* voice-map speech))) 
                    (throw 'result command)))) minor-mode-map-alist)
    nil))

(defun serenade--find-in-active-major-map (speech) 
  (if-let* ((current-mode-map (ht-get serenade-speech-maps (symbol-name major-mode)))) 
      (ht-get* current-mode-map speech)))

(defun serenade--find-in-global-map (speech) 
  (ht-get* serenade-speech-maps "global" speech))

(defun serenade-helm-commands () 
  "This function provides all current speech bindings in a helm buffer." 
  (interactive) 
  (helm :sources (helm-build-sync-source "serenade" 
                   :candidates (serenade--get-helm-candidates serenade-speech-maps)) 
        :buffer "*helm serenade*"))

(defun serenade-helm-active-commands () 
  "This function provides all current active speech bindings in a helm buffer." 
  (interactive) 
  (helm :sources (helm-build-sync-source "serenade" 
                   :candidates (serenade--get-helm-active-candidates serenade-speech-maps)) 
        :buffer "*helm serenade*"))

(defun serenade-helm-selectors () 
  "This function provides all current active speech bindings in a helm buffer." 
  (interactive) 
  (helm :sources (helm-build-sync-source "serenade" 
                   :candidates (serenade--get-helm-selectors serenade--selectors)) 
        :buffer "*helm serenade*"))

(provide 'serenade-commands)
