
(defvar serenade-directory "~/.serenade/scripts/"
  ;;The directory in which to save auto-generated Serenade custom commands.
  )

(defvar serenade-autogenerated-filepath  (concat serenade-directory "emacsAutogenerated.js"))

(defvar serenade-sync-on-start t 
  "If non-nil, generate autogenerated commands for serenade on mode start.")

(defun serenade--clear-formatted-commands () 
  (setq serenade--formatted-commands--no-slots '()) 
  (setq serenade--formatted-commands--named-slots '()))

(setq serenade-template-string "serenade.app(\"emacs\").command(`%s`, async (api, matches) => {
    api.evaluateInPlugin(`(%s)`)
});" )

(setq serenade--template-fragment-1 "let emacs = serenade.app(\"Emacs\");")

(setq serenade--template-fragment-2
      "function addEmacsCommands() { for (const [commandName, command] of Object.entries(emacsCommands)) { serenade.app(\"emacs\").command(commandName, async (api, matches) => { await api.evaluateInPlugin(emacsCommands[commandName]); }); } } addEmacsCommands();")

(defun serenade-list-to-string (l) 
  (mapconcat 'identity l ""))

(defun serenade--format-block--no-slots () 
  (format " let emacsCommands = {%s};" (serenade-list-to-string
                                        serenade--formatted-commands--no-slots)))

(defun serenade--format-command-without-slots (speech-and-command) 
  (format "\"%s\":\"(\\\"%s\\\")\"," (car speech-and-command) 
          (car speech-and-command)))

(defun serenade--format-command-call (speech-and-command) 
  (let* ((trimmed (concat "\""(nth 0 speech-and-command) "\""))) trimmed))

(defun serenade--format-call-matches (speech-and-command)
  ;; generate the alist of match name to match value, by first extracting the match names, then formatting them with their substitutions
  (let* ((sp (s-match-strings-all "<\\(.+?\\\)>" (car speech-and-command))) 
         (form  (mapconcat 'identity (-map '(lambda (match) 
                                              (format "(%s)" ;;
                                                      (format  "\"%s\" . \"%s\"" ;;
                                                               (nth 1 match) 
                                                               (format "${matches.%s}" ;;
                                                                       (nth 1 match))))) sp) " "))) 
    (format "( %s)" form )))

(defun serenade--format-registered-name (speech-and-command) 
  (let* ((name (car speech-and-command)) 
         (rr (s-replace "<" "<%"(s-replace ">" "%>" name ))))rr))

(defun serenade--format-command-with-named-slots (speech-and-command) 
  (format
   "serenade.app(\"emacs\").command(`%s`, async (api, matches) => { api.evaluateInPlugin(`(%s %s )`) });"
   (serenade--format-registered-name speech-and-command)
   (serenade--format-command-call speech-and-command) 
   (serenade--format-call-matches speech-and-command)))

(defun serenade--format-command (speech-and-command)
  ;; determine command type and add to appropriate command list
  (cond ((s-match "<.+>" (car speech-and-command )) 
         (add-to-list 'serenade--formatted-commands--named-slots
                      (serenade--format-command-with-named-slots speech-and-command)))
        ('t (add-to-list 'serenade--formatted-commands--no-slots
                         (serenade--format-command-without-slots speech-and-command)))))

(defun serenade--is-default-binding (key speech binding) 
  (and (string-equal key "global") 
       (assoc speech serenade--builtin-global-defaults)))

(defun serenade--format-commands () 
  (serenade--clear-formatted-commands) 
  (ht-each '(lambda (key value) 
              (ht-each '(lambda (speech binding) 
                          (if (serenade--is-default-binding key speech binding) ;;
                              nil (let* ((command (ht-get* binding "command"))) 
                                    (serenade--format-command (list speech command))))) value))
           serenade-speech-maps))

(defun serenade--generate-combined-text () 
  (concat serenade--template-fragment-1 ( serenade--format-block--no-slots )
          serenade--template-fragment-2 (serenade-list-to-string
                                         serenade--formatted-commands--named-slots)))

(defun serenade--generate () 
  (serenade--format-commands) 
  (let* ((final (serenade--generate-combined-text)) 
         (fpath serenade-autogenerated-filepath)) 
    (with-temp-file fpath (insert final)) 
    (serenade--info (concat "exported js, slots: " (number-to-string(length
                                                                     serenade--formatted-commands--named-slots))
                            " no slots: " (number-to-string (length
                                                             serenade--formatted-commands--no-slots))))))

(defun serenade-open-autogenerated-file ()
  ;; this function opens the autogenerated custom commands file.
  (interactive) 
  (find-file serenade-autogenerated-filepath))

(defun serenade-generate ()
  ;; Convert custom commands added to serenade speech bindings to javascript.
  (interactive) 
  (serenade--generate))

(provide 'serenade-generate)
