;; (require 's)
(require 'ht)

(defvar serenade-directory "~/.serenade/scripts/")
(defvar serenade-sync-on-start t 
  "If non-nil, generate autogenerated commands for serenade on start.")

(defun serenade--clear-formatted-commands () 
  (setq serenade--formatted-commands--no-slots '()) 
  (setq serenade--formatted-commands--anonymous-slots '()) 
  (setq serenade--formatted-commands--named-slots '()))

(setq serenade-template-string "serenade.app(\"emacs\").command(`%s`, async (api, matches) => {
    api.evaluateInPlugin(`(%s)`)
});" )

(setq serenade--template-fragment-1 "let emacs = serenade.app(\"Emacs\");")

(setq serenade--template-fragment-2
      "function addEmacsCommands() { for (const [commandName, command] of Object.entries(emacsCommands)) { serenade.app(\"emacs\").command(commandName, async (api, matches) => { await api.evaluateInPlugin(emacsCommands[commandName]); }); } }")

(defun serenade-list-to-string (l) 
  (mapconcat 'identity l ""))

(defun serenade--format-block--no-slots () 
  (format " let emacsCommands = {%s};" (serenade-list-to-string
                                        serenade--formatted-commands--no-slots)))

(defun serenade--format-command-without-slots (speech-and-command) 
  (format "\"%s\":\"('%s')\"," (car speech-and-command) 
          (car (cdr speech-and-command))))

(defun serenade--format-speech-matches (speech-and-command) 
  (let* ((sp (s-match-strings-all "<\\(.+?\\\)>" (car speech-and-command))) 
         (form  (s-join " "(-map '(lambda (match) 
                                    (format "%s"(format "<%%%s%%>" (nth 1 match)))) sp)))) form))

(defun serenade--format-speech (speech-and-command) 
  (s-trim (first (s-split "<" (car speech-and-command) ))))

(defun serenade--format-command-call (speech-and-command) 
  (let* ((trimmed (concat "'"(nth 0 speech-and-command) "'"))) trimmed))

(defun serenade--format-call-matches (speech-and-command) 
  (let* ((sp (s-match-strings-all "<\\(.+?\\\)>" (car speech-and-command))) 
         (form  (mapconcat 'identity (-map '(lambda (match) 
                                              (format "${matches.%s}"  (nth 1 match))) sp) " ")))
    form))

(defun serenade--format-command-with-named-slots (speech-and-command) 
  (format
   "serenade.app(\"emacs\").command(`%s %s`, async (api, matches) => { api.evaluateInPlugin(`(%s %s )`) });"
   (serenade--format-speech speech-and-command)
   (serenade--format-speech-matches speech-and-command) 
   (serenade--format-command-call speech-and-command) 
   (serenade--format-call-matches speech-and-command)))

(defun serenade--format-command (speech-and-command)
  ;; determine command type and add to appropriate command list
  (cond ((s-match "<.+>" (car speech-and-command )) 
         (add-to-list 'serenade--formatted-commands--named-slots
                      (serenade--format-command-with-named-slots speech-and-command)))
        ;; ((s-match "%s" speech)
        ;;  (add-to-list 'serenade--formatted-commands--anonymous-slots
        ;;               (serenade--format-command-with-anonymous-slots speech e)))
        ('t (add-to-list 'serenade--formatted-commands--no-slots
                         (serenade--format-command-without-slots speech-and-command)))))

(defun serenade--is-default-binding (key speech binding) 
  (and (string-equal key "global") 
       (and (assoc speech serenade--global-defaults) 
            (eq (cdr (assoc speech serenade--global-defaults)) 
                (ht-get* binding "command")))))

(defun serenade--format-commands () 
  (serenade--clear-formatted-commands) 
  (ht-each '(lambda (key value) 
              (ht-each '(lambda (speech binding) 
                          (if (serenade--is-default-binding key speech binding) nil (let* ((command
                                                                                            (ht-get*
                                                                                             binding
                                                                                             "command")))
                                                                                      (serenade--format-command
                                                                                       (list speech
                                                                                             command)))))
                       value)) serenade-mode-maps))

(defun serenade--generate-combined-text () 
  (concat serenade--template-fragment-1 ( serenade--format-block--no-slots )
          serenade--template-fragment-2 (serenade-list-to-string
                                         serenade--formatted-commands--named-slots)))

(defun serenade--synchronize () 
  (serenade--format-commands) 
  (let* ((final (serenade--generate-combined-text)) 
         (name-input "emacsAutogenerated.js") 
         (fpath (concat serenade-directory name-input))) 
    (with-temp-file fpath (insert final) 
                    (find-file fpath))))

(defun serenade-synchronize () 
  (interactive) 
  (serenade--synchronize))

(provide 'serenade-synchronize)
