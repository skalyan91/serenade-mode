
;;; serenade-mode.el --- serenade mode -*- lexical-binding: t -*-

;; Author: Justin Roche
;; Maintainer: Justin Roche
;; Version: 0.0.1
;; Homepage: https://github.com/justin-roche/serenade-mode
;; Keywords: voice command
;; Package-Requires: ((dash "2.18.1")(log4e "0.3.3") (websocket "1.13")(s "1.12.0")(ht "2.4")   )

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

(require 'ht)
(require 'dash)
(require 's)
(require 'cl-lib)
(require 'websocket)
(require 'log4e)

(require 'serenade-socket)
(require 'serenade-editor-functions)
(require 'serenade-macros)
(require 'serenade-defaults)
(require 'serenade-commands)
(require 'serenade-modes)
(require 'serenade-log)
(require 'serenade-keys-patch)
(require 'serenade-generate)
(require 'serenade-desktop)
(require 'serenade-handler)

(defface helm-serenade-command '((t :foreground "#CD009600CD00" 
                                    :underline t)) 
  "Face for serenade helm.")
(defface helm-serenade-info '((t :foreground "#CD009600CD00" 
                                 :underline nil)) 
  "Face for serenade helm.")

(defcustom serenade-completion-frontend nil 
  "Sets the completion frontend to be used. If nil, completion support is disabled. If 'helm, uses helm for completion.")

(defcustom serenade-snippet-engine nil 
  "Sets the snippet engine to be used. Currently the only supported value is 'yasnippet. If nil, snippet support is disabled.")

(defcustom serenade-helm-M-x nil 
  "if t, display speech bindings in helm M-x")

(defcustom serenade-enable-double-line-numbers t 
  "if t, serenade mode shows both relative and absolute line numbers")

(defcustom serenade-mode-init-hook nil 
  "The list of functions to be called after `serenade-mode' has initialized all variables, before connecting fer for the first time." 
  :type 'hook 
  :group 'serenade-mode)

(defcustom serenade-mode-after-edit-hook nil 
  "The list of functions to be called after an edit has been made in response to a speech command." 
  :type 'hook 
  :group 'serenade-mode)

(setq serenade--auto-set-evil t )

(defun serenade--initialize-evil () 
  (if (bound-and-true-p evil-mode) 
      (setq serenade-evil t) 
    (setq serenade-evil nil ) ))

(defun serenade--initialize-completion-frontend () 
  "Conditionally reequire serenade-helm if serenade-completion-frontend is set to 'helm. If serenade-helm-M-x is true, set serenade--helm-M-x-active to true."
  (if (eq serenade-completion-frontend 'helm) 
      (progn 
        (require 'serenade-helm) 
        (if serenade-helm-M-x 
            (setq serenade--helm-M-x-active t) 
          (setq serenade--helm-M-x-active nil))) 
    (setq serenade--helm-M-x-active nil)))

(defun serenade--initialize-snippet-engine () 
  "Conditionally reequire serenade-snippet if serenade-snippet-engine is set to 'yasnippet."
  (if (eq serenade-snippet-engine 'yasnippet) 
      (progn 
        (require 'serenade-snippet))))

(defun serenade-mode--start () 
  "Called when the mode is started, this function is responsible for calling generate."
  (run-hooks 'serenade-mode-init-hook) 
  (serenade--info "connecting to serenade") 
  (serenade--initialize-completion-frontend) 
  (serenade--initialize-snippet-engine) 
  (if serenade--auto-set-evil (serenade--initialize-evil)) 
  (if serenade-enable-double-line-numbers (run-hooks 'serenade-double-line-numbers-on-hook)) 
  (if serenade-sync-on-start (serenade--generate)) 
  (if serenade--helm-M-x-active (serenade--advise-helm-transformer)) 
  (serenade--connect))

(defun serenade-mode-start () 
  (interactive) 
  (serenade-mode--start))

(defun serenade-mode--stop () 
  (serenade--info "disconnecting from serenade") 
  (if serenade-enable-double-line-numbers(run-hooks 'serenade-double-line-numbers-off-hook) ) 
  (if serenade-helm-M-x (serenade--unadvise-helm-transformer)) 
  (serenade--disconnect))

(defun serenade-mode-stop () 
  (interactive) 
  (serenade-mode--stop))

(defun serenade-mode-reconnect () 
  "Disconnect and reconnect to Serenade app." 
  (interactive) 
  (serenade-mode--stop) 
  (serenade-mode--start))

(defun serenade-mode-toggle () 
  (if serenade-mode (serenade-mode--start) 
    (serenade-mode--stop)))

(defvar serenade-mode-map (let ((map (make-sparse-keymap))) map))

(define-minor-mode serenade-mode "Toggle Serenade mode." 
  nil
  " Serenade" 
  :global t 
  :lighter " serenade" 
  :keymap serenade-mode-map 
  :group 'serenade-mode
  (serenade-mode-toggle))

(provide 'serenade-mode)

(with-eval-after-load "serenade-mode" (serenade--initialize-completion-frontend) 
                      (serenade--initialize-snippet-engine) 
                      (serenade--initialize-speech-maps) 
                      (serenade--initialize-mode-config-map))

;;; serenade-mode.el ends here
